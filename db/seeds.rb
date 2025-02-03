# frozen_string_literal: true

require "digest/md5"
require "tempfile"
require "net/http"

# Uncomment to see detailed logs
# ActiveRecord::Base.logger = ActiveSupport::Logger.new($stdout)

module Seeds
  def self.run!
    CurrentUser.user = User.system
    Posts.run!
  end

  def self.api_request(path)
    puts("-> GET #{base_url}#{path}")
    response = Faraday.get("#{base_url}#{path}", nil, user_agent: "InternalBooru/seeding")
    JSON.parse(response.body)
  end

  def self.base_url
    read_resources["base_url"]
  end

  def self.read_resources
    if @resources
      yield(@resources) if block_given?
      return @resources
    end
    @resources = YAML.load_file(Rails.root.join("db/seeds.yml"))
    @resources["tags"] << "randseed:#{Digest::MD5.hexdigest(Time.now.to_s)}" if @resources["tags"]&.include?("order:random")
    @resources["tags"] << "rating:s" if Posts.safe?
    yield(@resources) if block_given?
    @resources
  end

  module Posts
    MAX_PER_PAGE = 320

    def self.fetch_related_posts?
      Seeds.read_resources["fetch_related_posts"].to_s.truthy?
    end

    def self.safe?
      Seeds.read_resources["safe"].to_s.truthy?
    end

    def self.e621?
      Seeds.base_url.include?("e621.net")
    end

    def self.get_posts(tags, limit = ENV.fetch("SEED_POST_COUNT", 100), page = 1, logpage: true)
      posts = Seeds.api_request("/posts.json?limit=#{[MAX_PER_PAGE, limit].min}&tags=#{tags.join('%20')}&page=#{page}")
      posts = posts["posts"] if e621?
      puts("Get Page #{page}") if logpage
      limit -= posts.length
      if posts.length == MAX_PER_PAGE && limit > 0
        posts += get_posts(tags, limit, page + 1, logpage: logpage)
      end
      posts
    end

    def self.get_related_posts(post, from = [post["id"]])
      posts = []
      ids = Set.new

      if !post["relationships"]["parent_id"].nil? && from.exclude?(post["relationships"]["parent_id"])
        ids << post["relationships"]["parent_id"]
      end

      unless post["relationships"]["children"].empty?
        ids.merge(post["relationships"]["children"].reject { |id| from.include?(id) })
      end

      return posts if ids.empty?

      related = get_posts(%W[id:#{ids.to_a.join(',')}], MAX_PER_PAGE, logpage: false)
      posts.concat(related)

      related.each do |p|
        posts.concat(get_related_posts(p, from + ids.to_a + posts.pluck("id")))
      end

      posts.reject { |p| p["flags"]["deleted"] }
    end

    def self.create_with_relationships(ogpost)
      return create_post(ogpost) unless fetch_related_posts?
      related = get_related_posts(ogpost)
      original = [ogpost, *related]

      puts("Got #{related.length} related posts for ##{ogpost['id']}") unless related.empty?

      local = {}
      remote = {}
      posts = []
      original.each do |p|
        post = create_post(p)
        next if post.nil?
        posts << post
        remote[p["id"]] = post.id
        local[post.id] = p["id"]
      end

      local.each_key do |p|
        rp = original.find { |ps| ps["id"] == local[p] }
        post = posts.find { |ps| ps.id == p }
        parent = remote[rp["relationships"]["parent_id"]]
        next if post.parent_id == parent || parent.nil?
        post.update!(parent_id: parent)
      end
    end

    def self.create_post(post)
      resources = Seeds.read_resources
      existing = Post.find_by(md5: post["file"]["md5"])
      return existing if existing.present?
      url = get_url(post, resources["base_url"])
      puts(url)
      post["sources"] << "#{resources['base_url']}/posts/#{post['id']}"
      post["tags"].each do |category, tags|
        Tag.find_or_create_by_name_list(tags.map { |tag| "#{category}:#{tag}" })
      end

      service = UploadService.new({
        uploader_ip_addr: CurrentUser.ip_addr,
        direct_url:       url,
        tag_string:       post["tags"].values.flatten.join(" "),
        source:           post["sources"].join("\n"),
        description:      post["description"],
        rating:           post["rating"],
      })

      upload = service.start!

      if upload.errors.any?
        raise(StandardError, "Failed to create upload: #{upload.errors.full_messages}")
      end

      if upload.post&.errors&.any?
        raise(StandardError, "Failed to create post: #{upload.post.errors.full_messages}")
      end

      upload.post
    end

    def self.run!(limit = ENV.fetch("SEED_POST_COUNT", 100).to_i)
      resources = Seeds.read_resources
      search_tags = resources["post_ids"].blank? ? resources["tags"] : ["id:#{resources['post_ids'].join(',')}"]
      if search_tags.include?("order:random") && search_tags.none? { |tag| tag.starts_with?("randseed:") }
        search_tags << "randseed:#{SecureRandom.hex(16)}"
      end
      posts = get_posts(search_tags, limit)

      before = Post.count
      posts.map { |p| create_with_relationships(p) }
      after = Post.count
      puts("Created #{after - before} posts from #{posts.length} requested posts.")
    end

    def self.get_url(post, base_url)
      return post["file"]["url"] unless post["file"]["url"].nil?
      puts("post #{post['id']} returned a nil url, attempting to reconstruct url.")
      return "https://static1.e621.net/data/#{post['file']['md5'][0..1]}/#{post['file']['md5'][2..3]}/#{post['file']['md5']}.#{post['file']['ext']}" if /e621\.net/i =~ base_url
      "https://static.femboy.fan/#{post['file']['md5'][0..1]}/#{post['file']['md5'][2..3]}/#{post['file']['md5']}.#{post['file']['ext']}"
    end
  end
end

CurrentUser.as_system do
  ModAction.without_logging do
    unless Rails.env.test?
      Seeds.run!
    end
  end
end

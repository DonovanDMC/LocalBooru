# frozen_string_literal: true

module StatsUpdater
  module_function

  def run!
    stats = {}
    stats[:started] = User.system.created_at

    daily_average = ->(total) do
      (total / ((Time.now - stats[:started]) / (60 * 60 * 24))).round
    end

    ### Posts ###

    stats[:total_posts] = Post.maximum("id") || 0
    stats[:active_posts] = Post.tag_match("status:active").count_only
    stats[:deleted_posts] = Post.tag_match("status:deleted").count_only
    stats[:existing_posts] = stats[:active_posts] + stats[:deleted_posts]
    stats[:destroyed_posts] = stats[:total_posts] - stats[:existing_posts]
    stats[:total_favorites] = Favorite.count
    stats[:total_pools] = Pool.count

    stats[:average_posts_per_pool] = Pool.average(Arel.sql("cardinality(post_ids)")) || 0

    stats[:general_posts] = Post.tag_match("status:any rating:g").count_only
    stats[:adult_posts] = Post.tag_match("status:any rating:a").count_only
    stats[:jpg_posts] = Post.tag_match("status:any type:jpg").count_only
    stats[:png_posts] = Post.tag_match("status:any type:png").count_only
    stats[:gif_posts] = Post.tag_match("status:any type:gif").count_only
    stats[:webp_posts] = Post.tag_match("status:any type:webp").count_only
    stats[:webm_posts] = Post.tag_match("status:any type:webm").count_only
    stats[:mp4_posts] = Post.tag_match("status:any type:mp4").count_only
    stats[:average_file_size] = Post.average("file_size")
    stats[:total_file_size] = Post.sum("file_size")
    stats[:average_posts_per_day] = daily_average.call(stats[:total_posts])

    ### Tags ###

    stats[:total_tags] = Tag.count
    TagCategory.category_names.each do |cat|
      stats[:"#{cat}_tags"] = Tag.where(category: TagCategory.mapping[cat]).count
    end
    stats
  end

  def get
    Cache.fetch("ffstats", expires_in: 1.day) do
      run!.as_json
    end
  end
end

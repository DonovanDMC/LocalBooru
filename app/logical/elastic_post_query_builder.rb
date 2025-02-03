# frozen_string_literal: true

class ElasticPostQueryBuilder < ElasticQueryBuilder
  def initialize(query_string, resolve_aliases:, always_show_deleted:)
    super(TagQuery.new(query_string, resolve_aliases: resolve_aliases))
    @always_show_deleted = always_show_deleted
  end

  def model_class
    Post
  end

  def add_tag_string_search_relation(tags)
    must.concat(tags[:must].map { |x| { term: { tags: x } } })
    must_not.concat(tags[:must_not].map { |x| { term: { tags: x } } })
    should.concat(tags[:should].map { |x| { term: { tags: x } } })
  end

  def hide_deleted_posts?
    return false if @always_show_deleted
    return false if q[:status].in?(%w[deleted active any all modqueue appealed])
    return false if q[:status_must_not].in?(%w[deleted active any all])
    true
  end

  def build
    add_array_range_relation(:post_id, :id)
    add_array_range_relation(:mpixels, :mpixels)
    add_array_range_relation(:ratio, :aspect_ratio)
    add_array_range_relation(:width, :width)
    add_array_range_relation(:height, :height)
    add_array_range_relation(:duration, :duration)
    add_array_range_relation(:framecount, :framecount)
    add_array_range_relation(:filesize, :file_size)
    add_array_range_relation(:change_seq, :change_seq)
    add_array_range_relation(:date, :created_at)
    add_array_range_relation(:age, :created_at)

    TagCategory.category_names.each do |category|
      add_array_range_relation(:"#{category}_tag_count", "tag_count_#{category}")
    end

    add_array_range_relation(:post_tag_count, :tag_count)

    # TagQuery::COUNT_METATAGS.map(&:to_sym).each do |column|
    #  if q[column]
    #    relation = range_relation(q[column], column)
    #    must.push(relation) if relation
    #  end
    # end

    if q[:md5]
      must.push(match_any(*(q[:md5].map { |m| { term: { md5: m } } })))
    end

    if q[:status] == "deleted"
      must.push({ term: { deleted: true } })
    elsif q[:status] == "active"
      must.push({ term: { deleted: false } })
    elsif q[:status] == "all" || q[:status] == "any"
      # do nothing
      must_not.push(match_any({ term: { pending: true } }, { term: { flagged: true } }, { term: { appealed: true } }))
    elsif q[:status_must_not] == "deleted"
      must_not.push({ term: { deleted: true } })
    elsif q[:status_must_not] == "active"
      must.push(match_any({ term: { deleted: true } }))
    end

    if hide_deleted_posts?
      must.push({ term: { deleted: false } })
    end

    add_array_relation(:pool_ids, :pools, any_none_key: :pool)
    add_array_relation(:parent_ids, :parent, any_none_key: :parent)

    add_array_relation(:rating, :rating)
    add_array_relation(:filetype, :file_ext)
    add_array_relation(:delreason, :del_reason, action: :wildcard)
    add_array_relation(:description, :description, action: :match_phrase_prefix)
    add_array_relation(:sources, :source, any_none_key: :source, action: :wildcard, cast: :downcase)

    if q[:child] == "none"
      must.push({ term: { has_children: false } })
    elsif q[:child] == "any"
      must.push({ term: { has_children: true } })
    end

    add_boolean_exists_relation(:hassource, :source)
    add_boolean_exists_relation(:hasdescription, :description)
    add_boolean_exists_relation(:ischild, :parent)
    add_boolean_exists_relation(:isparent, :children)
    add_boolean_exists_relation(:inpool, :pools)
    add_boolean_relation(:pending_replacements, :has_pending_replacements)
    add_boolean_relation(:fav, :fav)

    add_tag_string_search_relation(q[:tags])

    case q[:order]
    when "id", "id_asc"
      order.push({ id: :asc })

    when "id_desc"
      order.push({ id: :desc })

    when "change", "change_desc"
      order.push({ change_seq: :desc })

    when "change_asc"
      order.push({ change_seq: :asc })

    when "md5"
      order.push({ md5: :desc })

    when "md5_asc"
      order.push({ md5: :asc })

    when "duration", "duration_desc"
      order.push({ duration: :desc }, { id: :desc })

    when "duration_asc"
      order.push({ duration: :asc }, { id: :asc })

    when "framecount", "framecount_desc"
      order.push({ framecount: :desc }, { id: :desc })

    when "framecount_asc"
      order.push({ framecount: :asc }, { id: :asc })

    when "created_at", "created_at_desc"
      order.push({ created_at: :desc })

    when "created_at_asc"
      order.push({ created_at: :asc })

    when "updated", "updated_desc"
      order.push({ updated_at: :desc }, { id: :desc })

    when "updated_asc"
      order.push({ updated_at: :asc }, { id: :asc })

    when "mpixels", "mpixels_desc"
      order.push({ mpixels: :desc })

    when "mpixels_asc"
      order.push({ mpixels: :asc })

    when "portrait"
      order.push({ aspect_ratio: :asc })

    when "landscape"
      order.push({ aspect_ratio: :desc })

    when "filesize", "filesize_desc"
      order.push({ file_size: :desc })

    when "filesize_asc"
      order.push({ file_size: :asc })

      # when /\A(?<column>#{TagQuery::COUNT_METATAGS.join('|')})(_(?<direction>asc|desc))?\z/i
      # column = Regexp.last_match[:column]
      # direction = Regexp.last_match[:direction] || "desc"
      # order.push({ column => direction }, { id: direction })

    when "tagcount", "tagcount_desc"
      order.push({ tag_count: :desc })

    when "tagcount_asc"
      order.push({ tag_count: :asc })

    when /(#{TagCategory.short_name_regex})tags(?:\Z|_desc)/
      order.push({ "tag_count_#{TagCategory.short_name_mapping[$1]}" => :desc })

    when /(#{TagCategory.short_name_regex})tags_asc/
      order.push({ "tag_count_#{TagCategory.short_name_mapping[$1]}" => :asc })

    when "random"
      if q[:random_seed].present?
        @function_score = {
          random_score: { seed: q[:random_seed], field: "id" },
          boost_mode:   :replace,
        }
      else
        @function_score = {
          random_score: {},
          boost_mode:   :replace,
        }
      end

      order.push({ _score: :desc })

    else # rubocop:disable Lint/DuplicateBranch
      order.push({ id: :desc })
    end
  end
end

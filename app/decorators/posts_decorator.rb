# frozen_string_literal: true

class PostsDecorator < ApplicationDecorator
  def self.collection_decorator_class
    PaginatedDecorator
  end

  alias post object

  delegate_all

  def preview_class(_options)
    klass = ["post-preview"]
    klass << "post-status-deleted" if post.is_deleted?
    klass << "post-status-has-parent" if post.parent_id
    klass << "post-status-has-children" if post.has_visible_children?
    klass << "post-rating-general" if post.rating == "g"
    klass << "post-rating-adult" if post.rating == "a"
    klass
  end

  def data_attributes
    { data: object.thumbnail_attributes }
  end

  def cropped_url(options)
    cropped_url = if FemboyFans.config.enable_image_cropping? && options[:show_cropped] && object.has_cropped? && !CurrentUser.user.disable_cropped_thumbnails?
                    object.crop_file_url
                  else
                    object.preview_file_url
                  end

    cropped_url = FemboyFans.config.deleted_preview_url if object.deleteblocked?
    cropped_url
  end

  def score_class(score)
    return "score-neutral" if score == 0
    score > 0 ? "score-positive" : "score-negative"
  end

  def preview_html(template, options = {})
    return "" if post.nil?

    if !options[:show_deleted] && post.is_deleted? && options[:tags] !~ /(?:status:(?:all|any|deleted))|(?:deletedby:)|(?:delreason:)/i
      return ""
    end

    if post.loginblocked? || post.safeblocked?
      return ""
    end

    article_attrs = {
      id:    "post_#{post.id}",
      class: preview_class(options).join(" "),
    }.merge(data_attributes)

    link_target = options[:link_target] || post

    link_params = {}
    if options[:tags].present?
      link_params["q"] = options[:tags]
    end
    if options[:pool_id]
      link_params["pool_id"] = options[:pool_id]
    end

    tooltip = "Rating: #{post.rating}\nID: #{post.id}\nDate: #{post.created_at}\nStatus: #{post.status}"
    tooltip += "\nUploader: #{post.uploader_name}"
    if post.is_deleted?
      tooltip += "\nDel Reason: #{post.deletion_reason}"
    end
    tooltip += "\n\n#{post.tag_string}"

    cropped_url = if FemboyFans.config.enable_image_cropping? && options[:show_cropped] && post.has_cropped? && !CurrentUser.user.disable_cropped_thumbnails?
                    post.crop_file_url
                  else
                    post.preview_file_url
                  end

    cropped_url = FemboyFans.config.deleted_preview_url if post.deleteblocked?
    preview_url = if post.deleteblocked?
                    FemboyFans.config.deleted_preview_url
                  else
                    post.preview_file_url
                  end

    alt_text = post.tag_string

    has_cropped = post.has_cropped?

    pool = options[:pool]

    similarity = options[:similarity]&.round

    size = options[:size] ? post.file_size : nil

    img_contents = template.link_to(template.polymorphic_path(link_target, link_params)) do
      template.tag.picture do
        template.concat(template.tag.source(media: "(max-width: 800px)", srcset: cropped_url))
        template.concat(template.tag.source(media: "(min-width: 800px)", srcset: preview_url))
        template.concat(template.tag.img(class: "has-cropped-#{has_cropped}", src: preview_url, title: tooltip, alt: alt_text))
      end
    end
    desc_contents = if options[:stats] || pool || similarity || size
                      template.tag.div(class: "desc") do
                        template.post_stats_section(post) if options[:stats]
                      end
                    else
                      "".html_safe
                    end

    ribbons = ribbons(template)
    vote_buttons = vote_buttons(template)
    template.tag.article(**article_attrs) do
      img_contents + desc_contents + ribbons + vote_buttons
    end
  end

  def ribbons(template)
    template.tag.div(class: "ribbons") do
      [if post.parent_id.present?
         if post.has_visible_children?
           template.tag.div(class: "ribbon left has-parent has-children", title: "Has Parent\nHas Children") do
             template.tag.span
           end
         else
           template.tag.div(class: "ribbon left has-parent", title: "Has Parent") do
             template.tag.span
           end
         end
       elsif post.has_visible_children?
         template.tag.div(class: "ribbon left has-children", title: "Has Children") do
           template.tag.span
         end
       end,
       if post.is_deleted?
         template.tag.div(class: "ribbon right is-deleted", title: "Deleted") do
           template.tag.span
         end
       end,].join.html_safe
    end
  end

  def vote_buttons(template)
    template.tag.div(id: "vote-buttons") do
      template.tag.button("", class: "button vote-button fav score-neutral", data: { action: "fav", state: post.is_favorited? }) do
        template.tag.span(class: "post-favorite-#{post.id} score-neutral#{post.is_favorited? ? ' is-favorited' : ''}")
      end
    end
  end
end

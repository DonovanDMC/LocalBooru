# frozen_string_literal: true

module TagsHelper
  def format_transitive_item(transitive)
    html = "<strong class=\"text-error\">#{transitive[0].to_s.titlecase}</strong> ".html_safe
    if transitive[0] == :alias
      html << "#{transitive[2]} -> #{transitive[3]} will become #{transitive[2]} -> #{transitive[4]}"
    else
      html << "#{transitive[2]} +> #{transitive[3]} will become #{transitive[4]} +> #{transitive[5]}"
    end
    html
  end

  def tag_class(tag)
    return nil if tag.blank?
    "tag-type-#{tag.category}"
  end

  def link_to_tag(tag)
    link_to(tag.name, tag_path(tag), class: tag_class(tag))
  end

  def multiple_link_to_tag(tags)
    safe_join(tags.map { |tag| link_to_tag(tag) }, ", ")
  end
end

# frozen_string_literal: true

module CreatorsHelper
  def link_to_creator(name, hide_new_notice: false)
    creator = Creator.find_by(name: name)

    if creator
      link_to(creator.name, creator_path(creator))
    else
      link = link_to(name, new_creator_path(creator: { name: name }))
      return link.html_safe if hide_new_notice
      notice = tag.span("*", class: "new-creator", title: "No creator with this name currently exists.")
      "#{link} #{notice}".html_safe
    end
  end

  def link_to_creators(names, hide_new_notice: false)
    names.map do |name|
      link_to_creator(name.downcase, hide_new_notice: hide_new_notice)
    end.join(", ").html_safe
  end

  def link_to_pool_creators(names)
    names.map do |name|
      tag = Tag.find_or_create_by_name(name, user: User.system)
      link_to(name, show_or_new_creators_path(name: name), class: "tag-type-#{tag.category}")
    end.join(", ").html_safe
  end
end

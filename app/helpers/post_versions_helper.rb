# frozen_string_literal: true

module PostVersionsHelper
  def post_source_diff(post_version)
    diff = post_version.diff_sources(post_version.previous)
    changes = []

    diff[:added_sources].each do |source|
      classes = diff[:obsolete_added_sources].include?(source) ? "obsolete" : ""
      changes << tag.div(tag.ins(wordbreak_source("+#{source}"), class: classes))
    end
    diff[:removed_sources].each do |source|
      classes = diff[:obsolete_removed_sources].include?(source) ? "obsolete" : ""
      changes << tag.div(tag.del(wordbreak_source("-#{source}"), class: classes))
    end
    diff[:unchanged_sources].each do |source|
      changes << tag.div(wordbreak_source(source))
    end

    tag.span(safe_join(changes, " "), class: "diff-list")
  end

  def wordbreak_source(string)
    lines = string.scan(/.{1,10}/)
    safe_join(lines, tag.wbr)
  end

  def post_version_diff(post_version)
    diff = post_version.diff(post_version.previous)
    changes = []

    diff[:added_tags].each do |tag_name|
      classes = diff[:obsolete_added_tags].include?(tag_name) ? "obsolete" : ""
      changes << tag.ins("+#{tag_name}", class: classes)
    end
    diff[:removed_tags].each do |tag_name|
      classes = diff[:obsolete_removed_tags].include?(tag_name) ? "obsolete" : ""
      changes << tag.del("-#{tag_name}", class: classes)
    end
    diff[:unchanged_tags].each do |tag_name|
      changes << tag.span(tag_name)
    end

    tag.span(safe_join(changes, " "), class: "diff-list")
  end
end

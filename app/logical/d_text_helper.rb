# frozen_string_literal: true

module DTextHelper
  module_function

  def parse(text, **)
    return nil if text.nil?
    *data = preprocess([text])
    hash = DText.parse(text, **)
    hash[:dtext] = postprocess(hash[:dtext], *data)
    hash
  end

  def format_text(text, **)
    parse(text, **).fetch(:dtext)
  end

  def preprocess(dtext_messages)
    names = dtext_messages.map { |message| parse_creator_names(message) }.flatten.uniq
    creators = Creator.where(title: names)
    tags = Tag.where(name: names)
    [creators, tags]
  end

  def postprocess(html, creators, tags)
    fragment = parse_html(html)

    fragment.css("a.dtext-creator-link").each do |node|
      path = Addressable::URI.parse(node["href"]).path
      name = path[%r{\A/creators/(.*)\z}i, 1]
      name = CGI.unescape(name)
      name = Creator.normalize_name(name)
      tag = tags.find { |t| t.name == name }
      creator = creators.find { |a| a.name == name }

      if tag.present?
        node["class"] += " tag-type-#{tag.category}"
      end

      if tag.present? && tag.creator?
        node["href"] = "/creators/show_or_new?name=#{CGI.escape(name)}"

        if creator.blank?
          node["class"] += " dtext-creator-does-not-exist"
          node["title"] = "This creator page does not exist"
        end
      elsif tag.blank?
        node["class"] += " dtext-tag-does-not-exist"
        node["title"] = "This creator page does not have a tag"
      elsif tag.empty?
        node["class"] += " dtext-tag-empty"
        node["title"] = "This creator page does not have a tag"
      end
    end
    fragment.to_s
  end

  def parse_creator_names(text)
    return [] if text.blank?
    DText.parse(text) => { dtext: html }
    fragment = parse_html(html)

    titles = fragment.css("a.dtext-creator-link").map do |node|
      if node["href"].include?("show_or_new")
        title = node["href"][%r{\A/creators/show_or_new\?name=(.*)\z}i, 1]
      else
        title = node["href"][%r{\A/creators/(.*)\z}i, 1]
      end
      title = CGI.unescape(title)
      title = Creator.normalize_title(title)
      title
    end

    titles.uniq
  end

  def parse_external_links(text)
    return [] if text.blank?
    DText.parse(text) => { dtext: html }
    fragment = parse_html(html)

    links = fragment.css("a.dtext-external-link").pluck("href")
    links.uniq
  end

  def dtext_links_differ?(old, new)
    Set.new(parse_creator_names(old)) != Set.new(parse_creator_names(new)) ||
      Set.new(parse_external_links(old)) != Set.new(parse_external_links(new))
  end

  def parse_html(html)
    Nokogiri::HTML5.fragment(html, max_tree_depth: -1)
  end
end

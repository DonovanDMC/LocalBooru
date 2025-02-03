# frozen_string_literal: true

module PostsHelper
  def discover_mode?
    params[:tags] =~ /order:rank/
  end

  def next_page_url
    current_page = (params[:page] || 1).to_i
    url_for(nav_params_for(current_page + 1)).html_safe
  end

  def prev_page_url
    current_page = (params[:page] || 1).to_i
    if current_page >= 2
      url_for(nav_params_for(current_page - 1)).html_safe
    end
  end

  def post_source_tag(source)
    # Only allow http:// and https:// links. Disallow javascript: links.
    if source =~ %r{\Ahttps?://}i
      source_link = decorated_link_to(source.sub(%r{\Ahttps?://(?:www\.)?}i, ""), source, target: "_blank", rel: "nofollow noreferrer noopener")

      source_link += " ".html_safe + link_to("»", posts_path(tags: "source:#{source.sub(%r{[^/]*$}, '')}"), rel: "nofollow")

      source_link
    elsif source.start_with?("-")
      tag.s(source[1..])
    else
      source
    end
  end

  def has_parent_message(post, parent_post_set)
    html = +""

    html += "Parent: "
    html += link_to("post ##{post.parent_id}", post_path(id: post.parent_id))
    html += " (deleted)" if parent_post_set.parent.first.is_deleted?

    sibling_count = parent_post_set.children.count - 1
    if sibling_count > 0
      html += " that has "
      text = sibling_count == 1 ? "a sibling" : "#{sibling_count} siblings"
      html += link_to(text, posts_path(tags: "parent:#{post.parent_id}"))
    end

    html += link_to("show »", "#", id: "has-parent-relationship-preview-link")

    html.html_safe
  end

  def has_children_message(post, children_post_set)
    html = +""

    html += "Children: "
    text = children_post_set.children.count == 1 ? "1 child" : "#{children_post_set.children.count} children"
    html += link_to(text, posts_path(tags: "parent:#{post.id}"))

    html += link_to("show »", "#", id: "has-children-relationship-preview-link")

    html.html_safe
  end

  def is_pool_selected?(pool)
    return false if params.key?(:q)
    return false if params.key?(:post_set_id)
    return false unless params.key?(:pool_id)
    params[:pool_id].to_i == pool.id
  end

  def post_stats_section(post)
    favs = tag.span(class: "post-score-faves post-score-faves-classes-#{post.id}") do
      icon = tag.span("♥", class: "post-score-faves-icon-#{post.id}")
      amount = tag.span(post.is_favorited? ? "Y" : "N", class: "post-score-faves-faves-#{post.id}")
      icon + amount
    end
    rating = tag.span(post.rating.upcase, class: "post-score-rating")
    tag.div(favs + rating, class: "post-score", id: "post-score-#{post.id}")
  end

  private

  def nav_params_for(page)
    query_params = params.except(:controller, :action, :id).merge(page: page).permit!
    { params: query_params }
  end

  def pretty_html_rating(post)
    rating_text = post.pretty_rating
    rating_class = "post-rating-text-#{rating_text.downcase}"
    tag.span(rating_text, id: "post-rating-text", class: rating_class)
  end

  def rating_collection
    [
      %w[Safe s],
      %w[Questionable q],
      %w[Explicit e],
    ]
  end

  def post_ribbons(post)
    tag.div(class: "ribbons") do
      [if post.parent_id.present?
         if post.has_visible_children?
           tag.div(class: "ribbon left has-parent has-children", title: "Has Parent\nHas Children") do
             tag.span
           end
         else
           tag.div(class: "ribbon left has-parent", title: "Has Parent") do
             tag.span
           end
         end
       elsif post.has_visible_children?
         tag.div(class: "ribbon left has-children", title: "Has Children") do
           tag.span
         end
       end,
       if post.is_deleted?
         tag.div(class: "ribbon right is-deleted", title: "Pending") do
           tag.span
         end
       end,].join.html_safe
    end
  end

  def post_vote_buttons(post)
    tag.div(id: "vote-buttons") do
      tag.button("", class: "button vote-button fav score-neutral", data: { action: "fav", state: post.is_favorited? }) do
        tag.span(class: "post-favorite-#{post.id} score-neutral#{post.is_favorited? ? ' is-favorited' : ''}")
      end
    end
  end
end

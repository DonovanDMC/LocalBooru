# frozen_string_literal: true

module ApplicationHelper
  def disable_mobile_mode?
    cookies[:nmm].present?
  end

  def diff_list_html(new, old, latest)
    diff = SetDiff.new(new, old, latest)
    render("diff_list", diff: diff)
  end

  def nav_link_to(text, url, **options)
    klass = options.delete(:class)

    if nav_link_match(params[:controller], url)
      klass = "#{klass} current"
    end

    li_link_to_id(text, url, id_prefix: "nav-", class: klass, **options)
  end

  def subnav_link_to(text, url, **)
    li_link_to_id(text, url, id_prefix: "subnav-", **)
  end

  def li_link_to(text, url, li_options: {}, **options)
    klass = options.delete(:class)
    tag.li(link_to(text, url, **options), class: klass, **li_options)
  end

  def li_link_to_id(text, url, id_prefix: "", li_options: {}, **)
    id = id_prefix + text.downcase.gsub(/[^a-z ]/, "").parameterize
    li_link_to(text, url, li_options: { **li_options, id: id }, **, id: "#{id}-link")
  end

  def dtext_ragel(text, **)
    parsed = DTextHelper.parse(text, **)
    return raw("") if parsed.nil?
    deferred_post_ids.merge(parsed[:post_ids]) if parsed[:post_ids].present?
    raw(parsed[:dtext])
  rescue DText::Error
    raw("")
  end

  def format_text(text, **options)
    # preserve the current inline behaviour
    if options[:inline]
      dtext_ragel(text, **options)
    else
      raw(%(<div class="styled-dtext">#{dtext_ragel(text, **options)}</div>))
    end
  end

  def custom_form_for(object, *args, &)
    options = args.extract_options!
    simple_form_for(object, *(args << options.merge(builder: CustomFormBuilder)), &)
  end

  def error_messages_for(instance_name)
    instance = instance_variable_get("@#{instance_name}")

    if instance&.errors&.any?
      %(<div class="error-messages ui-state-error ui-corner-all"><strong>Error</strong>: #{instance.__send__(:errors).full_messages.join(', ')}</div>).html_safe
    else
      ""
    end
  end

  def time_tag(content, time)
    datetime = time.strftime("%Y-%m-%dT%H:%M%:z")
    tag.time(content || datetime, datetime: datetime, title: time.to_fs)
  end

  def time_ago_in_words_tagged(time, compact: false)
    if time.nil?
      tag.em(tag.time("unknown"))
    elsif time.past?
      text = "#{time_ago_in_words(time)} ago"
      text = text.gsub(/almost|about|over/, "") if compact
      raw(time_tag(text, time))
    else
      raw(time_tag("in #{distance_of_time_in_words(Time.now, time)}", time))
    end
  end

  def compact_time(time)
    time_tag(time.strftime("%Y-%m-%d %H:%M"), time)
  end

  def external_link_to(url, truncate: nil, strip_scheme: false, link_options: {})
    text = url
    text = text.gsub(%r{\Ahttps?://}i, "") if strip_scheme
    text = text.truncate(truncate) if truncate

    if url =~ %r{\Ahttps?://}i
      link_to(text, url, { rel: :nofollow }.merge(link_options))
    else
      url
    end
  end

  def link_to_user(user)
    user ||= User.anonymous

    user_class = ""
    user_class += " user-is-member" if user.is_member?
    user_class += " user-is-anonymous" if user.is_anonymous?
    user_class += " user-is-system" if user.is_system?
    link_to(user.name, "#", class: user_class, rel: "nofollow")
  end

  def table_for(...)
    table = TableBuilder.new(...)
    render(partial: "table_builder/table", locals: { table: table })
  end

  def body_attributes(user = CurrentUser.user)
    attributes = %i[name ip_addr per_page is_anonymous? is_member? is_system?]

    controller_param = params[:controller].parameterize.dasherize
    action_param = params[:action].parameterize.dasherize

    {
      lang:  "en",
      class: "c-#{controller_param} a-#{action_param} #{'resp' unless disable_mobile_mode?}",
      data:  {
        controller: controller_param,
        action:     action_param,
        **data_attributes_for(user, attributes, prefix: "user"),
      },
    }
  end

  def data_attributes_for(record, attributes = record.html_data_attributes, prefix: "data")
    attributes.flat_map do |attr|
      # If we have a hash, we assume this hash is a key-value of (relation, attributes)
      # [:is_read?, { category: %i[id name] }]
      if attr.is_a?(Hash)
        attr.flat_map do |key, sub_attrs|
          data_attributes_for(record.send(key), sub_attrs, prefix: "#{prefix}-#{key}").to_a
        end
      else
        name = attr.to_s.dasherize.delete("?")
        value = record.send(attr)
        if value.is_a?(ApplicationRecord)
          data_attributes_for(value, prefix: "#{prefix}-#{name}").to_a
        else
          [[:"#{prefix}-#{name}", value]]
        end
      end
    end.to_h
  end

  protected

  def nav_link_match(controller, url)
    # Static routes must match completely
    return url == request.path if controller == "static"

    url =~ case controller
           when "posts", "uploads", "posts/versions", "favorites"
             %r{^/posts}

           when "tags", "meta_searches", "tags/aliases", "tags/implications", "tags/related"
             %r{^/tags}

           when "pools", "pools/versions"
             %r{^/pools}

           # If there is no match activate the site map only
           else
             /^#{site_map_path}/
           end
  end

  def sitemap_link(url, **options)
    <<~XML.html_safe
      <url>
        <loc>#{url}</loc>
        #{options.map { |k, v| "<#{k}>#{v}</#{k}>" }.join("\n")}
      </url>
    XML
  end
end

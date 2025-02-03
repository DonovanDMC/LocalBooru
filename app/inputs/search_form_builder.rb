# frozen_string_literal: true

class SearchFormBuilder < SimpleForm::FormBuilder
  def policy
    @policy ||= @options[:policy]
  end

  def input(attribute_name, options = {}, &)
    ipolicy = options.delete(:policy)
    if ipolicy != false && (ipolicy || policy).present? && !(ipolicy || policy).can_search_attribute?(attribute_name)
      return "".html_safe
    end
    value = value_for_attribute(attribute_name, options)
    return "".html_safe if value.nil? && options[:hide_unless_value]
    options = insert_autocomplete(options)
    options = insert_value(value, options)
    super
  end

  def user(user_attribute, **args)
    if user_attribute.is_a?(String)
      user_attribute = user_attribute.to_sym
    else
      user_attribute = :"#{user_attribute}_ip_addr"
    end
    args[:label] ||= user_attribute.to_s.titleize.gsub("Ip", "IP")

    input(user_attribute, args)
  end

  private

  def insert_value(value, options)
    return options if value.nil?

    if options[:collection]
      options[:selected] = value
    elsif options[:as]&.to_sym == :boolean
      options[:input_html][:checked] = true if value.truthy?
    else
      options[:input_html][:value] = value
    end
    options
  end

  def value_for_attribute(attribute_name, options)
    @options[:search_params][attribute_name] || options[:default]&.to_s
  end

  include FormBuilderCommon
end

# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  concerning :SearchMethods do
    class_methods do
      def paginate(page, options = {})
        extending(FemboyFans::Paginator::ActiveRecordExtension).paginate(page, options)
      end

      def paginate_posts(page, options = {})
        extending(FemboyFans::Paginator::ActiveRecordExtension).paginate_posts(page, options)
      end

      def qualified_column_for(attr)
        "#{table_name}.#{column_for_attribute(attr).name}"
      end

      def where_like(attr, value)
        where("#{qualified_column_for(attr)} LIKE ? ESCAPE E'\\\\'", value.to_escaped_for_sql_like)
      end

      def where_ilike(attr, value)
        where("lower(#{qualified_column_for(attr)}) LIKE ? ESCAPE E'\\\\'", value.downcase.to_escaped_for_sql_like)
      end

      def attribute_exact_matches(attribute, value, **_options)
        return all if value.blank?

        column = qualified_column_for(attribute)
        where("#{column} = ?", value)
      end

      def attribute_matches(attribute, value, **)
        return all if value.nil?

        column = column_for_attribute(attribute)
        case column.sql_type_metadata.type
        when :boolean
          boolean_attribute_matches(attribute, value)
        when :integer, :datetime
          numeric_attribute_matches(attribute, value)
        when :string, :text
          text_attribute_matches(attribute, value, **)
        else
          raise(ArgumentError, "unhandled column type")
        end
      end

      def boolean_attribute_matches(attribute, value)
        if value.to_s.truthy?
          value = true
        elsif value.to_s.falsy?
          value = false
        else
          raise(ArgumentError, "value must be truthy or falsy")
        end

        where(attribute => value)
      end

      # range: "5", ">5", "<5", ">=5", "<=5", "5..10", "5,6,7"
      def numeric_attribute_matches(attribute, range)
        column = column_for_attribute(attribute)
        qualified_column = "#{table_name}.#{column.name}"
        parsed_range = ParseValue.range(range, column.type)

        add_range_relation(parsed_range, qualified_column)
      end

      def add_range_relation(arr, field)
        return all if arr.nil?

        case arr[0]
        when :eq
          if arr[1].is_a?(Time)
            where("#{field} between ? and ?", arr[1].beginning_of_day, arr[1].end_of_day)
          else
            where(["#{field} = ?", arr[1]])
          end
        when :gt
          where(["#{field} > ?", arr[1]])
        when :gte
          where(["#{field} >= ?", arr[1]])
        when :lt
          where(["#{field} < ?", arr[1]])
        when :lte
          where(["#{field} <= ?", arr[1]])
        when :in
          where(["#{field} in (?)", arr[1]])
        when :between
          where(["#{field} BETWEEN ? AND ?", arr[1], arr[2]])
        else
          all
        end
      end

      def
        text_attribute_matches(attribute, value, convert_to_wildcard: false)
        column = column_for_attribute(attribute)
        qualified_column = "#{table_name}.#{column.name}"
        value = "*#{value}*" if convert_to_wildcard && value.exclude?("*")

        if value =~ /\*/
          where("lower(#{qualified_column}) LIKE :value ESCAPE E'\\\\'", value: value.downcase.to_escaped_for_sql_like)
        else
          where("to_tsvector(:ts_config, #{qualified_column}) @@ plainto_tsquery(:ts_config, :value)", ts_config: "english", value: value)
        end
      end

      # Searches for a user by ip address.
      def where_user(db_field, query_field, params)
        return all if params[query_field].blank?
        where("#{db_field} <<= ?", params[query_field])
      end

      def apply_basic_order(params)
        case params[:order]
        when "id_asc"
          order(id: :asc)
        when "id_desc"
          order(id: :desc)
        else
          default_order
        end
      end

      def default_order
        order(id: :desc)
      end

      def search(params)
        params ||= {}

        q = all
        q = q.attribute_matches(:id, params[:id])
        q = q.attribute_matches(:created_at, params[:created_at]) if attribute_names.include?("created_at")
        q = q.attribute_matches(:updated_at, params[:updated_at]) if attribute_names.include?("updated_at")

        q
      end

      private

      # to_where_hash(:a, 1) => { a: 1 }
      # to_where_hash(a: :b, 1) => { a: { b: 1 } }
      def to_where_hash(field, value)
        if field.is_a?(Symbol)
          { field => value }
        elsif field.is_a?(Hash) && field.size == 1 && field.values.first.is_a?(Symbol)
          { field.keys.first => { field.values.first => value } }
        else
          raise(StandardError, "Unsupported field: #{field.class} => #{field}")
        end
      end
    end
  end

  module ApiMethods
    extend ActiveSupport::Concern

    module ClassMethods
      def available_includes
        []
      end

      def multiple_includes
        reflections.select { |_, v| v.macro == :has_many }.keys.map(&:to_sym)
      end

      def associated_models(name)
        if reflections[name].options[:polymorphic]
          reflections[name].active_record.try(:model_types) || []
        else
          [reflections[name].class_name]
        end
      end
    end

    def available_includes
      self.class.available_includes
    end

    # XXX deprecated, shouldn't expose this as an instance method.
    def api_attributes(user: CurrentUser.user)
      policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
      policy.api_attributes
    end

    # XXX deprecated, shouldn't expose this as an instance method.
    def html_data_attributes(user: CurrentUser.user)
      policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
      policy.html_data_attributes
    end

    def process_api_attributes(options, underscore: false)
      options[:methods] ||= []
      attributes, methods = api_attributes.partition { |attr| has_attribute?(attr) }
      methods += options[:methods]
      if underscore && options[:only].blank?
        options[:only] = attributes + methods
      else
        options[:only] ||= attributes + methods
      end

      attributes &= options[:only]
      methods &= options[:only]

      options[:only] = attributes
      options[:methods] = methods

      options.delete(:methods) if options[:methods].empty?
      options
    end

    def serializable_hash(options = {})
      options ||= {}
      return :not_visible unless visible?
      if options[:only].is_a?(String)
        options.delete(:methods)
        options.delete(:include)
        options.merge!(ParameterBuilder.serial_parameters(options[:only], self))
        if options[:only].include?("_")
          options[:only].delete("_")
          options = process_api_attributes(options, underscore: true)
        end
      else
        options = process_api_attributes(options)
      end
      options[:only] += [SecureRandom.hex(6)]

      hash = super(options)
      hash.transform_keys! { |key| key.delete("?") }
      deep_reject_hash(hash) { |_, v| v == :not_visible }
    end

    def visible?(_user = CurrentUser.user)
      true
    end

    def deep_reject_hash(hash, &block)
      hash.each_with_object({}) do |(key, value), result|
        if value.is_a?(Hash)
          result[key] = deep_reject_hash(value, &block)
        elsif value.is_a?(Array)
          result[key] = value.map { |v| v.is_a?(Hash) ? deep_reject_hash(v, &block) : v }.reject { |i| block.call(nil, i) }
        elsif !block.call(key, value)
          result[key] = value
        end
      end
    end
  end

  concerning :ActiveRecordExtensions do
    class_methods do
      def without_timeout
        connection.execute("SET STATEMENT_TIMEOUT = 0") unless Rails.env.test?
        yield
      ensure
        connection.execute("SET STATEMENT_TIMEOUT = #{FemboyFans.config.statement_timeout}") unless Rails.env.test?
      end

      def with_timeout(time, default_value = nil)
        connection.execute("SET STATEMENT_TIMEOUT = #{time}") unless Rails.env.test?
        yield
      rescue ::ActiveRecord::StatementInvalid => e
        FemboyFans::Logger.log(e, expected: true)
        default_value
      ensure
        connection.execute("SET STATEMENT_TIMEOUT = #{FemboyFans.config.statement_timeout}") unless Rails.env.test?
      end
    end
  end

  concerning :UserMethods do
    class_methods do
      def belongs_to_creator(column = :creator_ip_addr)
        column ||= :creator_ip_addr
        class_eval do
          before_validation(on: :create) do |rec|
            rec.send("#{column}=", CurrentUser.ip_addr)
          end

          # define_method(:creator) do
          #  User.new(send(column))
          # end

          # define_method(:creator_name) do
          #  User.new(send(column)).name
          # end
        end

        belongs_to_user(:creator, column)
      end

      def belongs_to_updater(column = :updater_ip_addr)
        column ||= :updater_ip_addr
        class_eval do
          before_validation(unless: :destroyed?) do |rec|
            rec.send("#{column}=", CurrentUser.ip_addr)
          end

          # define_method(:updater) do
          #  User.new(send(column))
          # end

          # define_method(:updater_name) do
          #  User.new(send(column)).name
          # end
        end

        belongs_to_user(:updater, column)
      end

      def belongs_to_user(attribute, column = "#{attribute}_ip_addr")
        class_eval do
          define_method(attribute) do
            val = send(column)
            val ? User.new(val) : nil
          end

          define_method(:"#{attribute}_name") do
            send(attribute).try(:name)
          end

          define_method("#{attribute}=") do |user|
            send("#{column}=", user.try(:ip_addr))
          end
        end
      end
    end
  end

  concerning :AttributeMethods do
    class_methods do
      # Defines `<column>_string`, `<column>_string=`, and `<column>=`
      # methods for converting an array column to or from a string.
      #
      # The `<column>=` setter parses strings into an array using the
      # `parse` regex. The resulting strings can be converted to another type
      # with the `cast` option.
      def array_attribute(name, parse: /[^[:space:]]+/, join_character: " ", cast: :itself)
        define_method("#{name}_string") do
          send(name).join(join_character)
        end

        define_method("#{name}_string=") do |value|
          raise(ArgumentError, "#{name} must be a String") unless value.respond_to?(:to_str)
          send("#{name}=", value)
        end

        define_method("#{name}=") do |value|
          if value.respond_to?(:to_str)
            super(value.to_str.scan(parse).flatten.map(&cast))
          elsif value.respond_to?(:to_a)
            super(value.to_a)
          else
            raise(ArgumentError, "#{name} must be a String or an Array")
          end
        end
      end
    end
  end

  concerning :PrivilegeMethods do
    class_methods do
      def visible(_user)
        all
      end

      def visible_for_search(attribute, current_user)
        policy(current_user).visible_for_search(all, attribute)
      end

      def policy(current_user)
        Pundit.policy(current_user, self)
      end
    end

    def policy(current_user)
      Pundit.policy(current_user, self)
    end
  end

  def warnings
    @warnings ||= ActiveModel::Errors.new(self)
  end

  include ApiMethods

  def self.override_route_key(value)
    define_singleton_method(:model_name) do
      mn = ActiveModel::Name.new(self)
      mn.instance_variable_set(:@route_key, value)
      mn
    end
  end

  def html_data_attributes(user = CurrentUser.user)
    policy = Pundit.policy(user, self) || ApplicationPolicy.new(user, self)
    policy.html_data_attributes
  end
end

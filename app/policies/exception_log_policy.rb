# frozen_string_literal: true

class ExceptionLogPolicy < ApplicationPolicy
  def permitted_search_params
    super + %i[commit class_name without_class_name user_ip_addr]
  end
end

# frozen_string_literal: true

class CreatorPolicy < ApplicationPolicy
  def permitted_attributes
    %i[other_names other_names_string url_string notes name]
  end

  def permitted_search_params
    super + %i[name any_other_name_like any_name_matches any_name_or_url_matches url_matches creator_ip_addr has_tag order]
  end
end

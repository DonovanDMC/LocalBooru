# frozen_string_literal: true

class CreatorVersion < ApplicationRecord
  array_attribute :urls
  array_attribute :other_names

  belongs_to_updater
  belongs_to :creator # Creator class

  module SearchMethods
    def search(params)
      q = super

      if params[:creator_name].present?
        q = q.where("name like ? escape E'\\\\'", params[:creator_name].to_escaped_for_sql_like)
      end

      q = q.where_user(:updater_ip_addr, :updater, params)

      if params[:creator_id].present?
        q = q.where(creator_id: params[:creator_id].split(",").map(&:to_i))
      end

      if params[:order] == "name"
        q = q.order("creator_versions.name").default_order
      else
        q = q.apply_basic_order(params)
      end

      q
    end
  end

  extend SearchMethods

  def previous
    CreatorVersion.where("creator_id = ? and created_at < ?", creator_id, created_at).order("created_at desc").first
  end

  def self.available_includes
    %i[creator]
  end
end

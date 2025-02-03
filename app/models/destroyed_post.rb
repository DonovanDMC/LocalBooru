# frozen_string_literal: true

class DestroyedPost < ApplicationRecord
  belongs_to_user :uploader
  belongs_to_user :destroyer

  module SearchMethods
    def search(params)
      q = super

      q = q.where_user(:destroyer_ip_addr, :destroyer_ip_addr, params)
      q = q.where_user(:uploader_ip_addr, :uploader_ip_addr, params)

      if params[:post_id].present?
        q = q.attribute_matches(:post_id, params[:post_id])
      end

      if params[:md5].present?
        q = q.attribute_matches(:md5, params[:md5])
      end

      if params[:reason_matches].present?
        q = q.attribute_matches(:reason, params[:reason_matches])
      end

      q.apply_basic_order(params)
    end
  end

  extend SearchMethods
end

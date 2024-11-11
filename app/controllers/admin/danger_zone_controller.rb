# frozen_string_literal: true

module Admin
  class DangerZoneController < ApplicationController
    def index
      authorize(:danger_zone)
    end

    def uploading_limits
      authorize(:danger_zone, :uploading_limits?)
      return render_expected_error(400, "min_level is missing") unless params[:uploading_limits].present? && params[:uploading_limits][:min_level].present?
      new_level = params[:uploading_limits][:min_level].to_i
      raise(ArgumentError, "#{new_level} is not valid") unless User::Levels.hash.values.include?(new_level)
      if new_level != DangerZone.min_upload_level
        old_level = DangerZone.min_upload_level
        DangerZone.min_upload_level = new_level
        StaffAuditLog.log!(:min_upload_level_change, CurrentUser.user, new_level: new_level, old_level: old_level)
      end
      redirect_to(admin_danger_zone_index_path)
    end

    def hide_pending_posts
      authorize(:danger_zone, :hide_pending_posts?)
      duration = params[:hide_pending_posts][:duration].to_f
      if duration >= 0 && duration != DangerZone.hide_pending_posts_for
        DangerZone.hide_pending_posts_for = duration
        StaffAuditLog.log(:hide_pending_posts_for, CurrentUser.user, { duration: duration })
      end
      redirect_to(admin_danger_zone_index_path)
    end
  end
end

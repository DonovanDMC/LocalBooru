# frozen_string_literal: true

require "test_helper"
require_relative "helper"

module ModActions
  class BulkUpdateRequestsTest < ActiveSupport::TestCase
    include Helper
    include Rails.application.routes.url_helpers

    context "mod actions for bulk update requests" do
      should "format mass_update correctly" do
        @bur = create(:bulk_update_request, skip_forum: true, script: "mass update aaa -> bbb")
        with_inline_jobs { @bur.approve!(@admin) }

        assert_matches(
          actions:    %w[mass_update],
          text:       "Mass updated [[aaa]] -> [[bbb]]",
          subject:    nil,
          antecedent: "aaa",
          consequent: "bbb",
        )
      end

      should "format nuke_tag correctly" do
        create(:post, tag_string: "aaa bbb")
        @bur = create(:bulk_update_request, skip_forum: true, script: "nuke aaa")
        with_inline_jobs { @bur.approve!(@admin) }

        assert_matches(
          actions:  %w[nuke_tag],
          text:     "Nuked tag [[aaa]]",
          subject:  Tag.find_by!(name: "aaa"),
          tag_name: "aaa",
        )
      end
    end
  end
end

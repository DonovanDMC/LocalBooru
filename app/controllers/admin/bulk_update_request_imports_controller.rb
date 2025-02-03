# frozen_string_literal: true

module Admin
  class BulkUpdateRequestImportsController < ApplicationController
    def new
    end

    def create
      bparams = params[:batch].presence || params
      @importer = BulkUpdateRequestImporter.new(bparams[:script])
      @importer.validate!
      begin
        ApplicationRecord.transaction { @importer.process! }
      rescue BulkUpdateRequestImporter::Error => e
        @error = e
        notice("Import failed")
        respond_to do |format|
          format.html { render(:new) }
          format.json { render_expected_error(400, e.message) }
        end
        return
      end
      notice("Import queued")
      respond_to do |format|
        format.html { redirect_to(new_admin_bulk_update_request_import_path) }
        format.json
      end
    end
  end
end

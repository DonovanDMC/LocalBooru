# frozen_string_literal: true

module Maintenance
  module_function

  def daily
    ignoring_exceptions { Upload.where("created_at < ?", 1.week.ago).delete_all }
    ignoring_exceptions { Tag.clean_up_negative_post_counts! }
    ignoring_exceptions { TagAlias.fix_nonzero_post_counts! }
    ignoring_exceptions { TagAlias.update_cached_post_counts_for_all }
    ignoring_exceptions { StatsUpdater.run! }
  end

  def hourly
  end

  def ignoring_exceptions
    ActiveRecord::Base.connection.execute("set statement_timeout = 0")
    yield
  rescue StandardError => e
    FemboyFans::Logger.log(e)
  end
end

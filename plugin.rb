# frozen_string_literal: true

# name: discourse-add-jobs-to-digest
# about: TODO
# meta_topic_id: TODO
# version: 0.0.1
# authors: Jay Pfaffman
# url: TODO
# required_version: 2.7.0

enabled_site_setting :discourse_add_jobs_to_digest_enabled
require "current_user"

module ::DiscourseAddJobsToDigest
  PLUGIN_NAME = "discourse-add-jobs-to-digest"
end

after_initialize do
  # Code which should run after Rails has finished booting

  # require_relative "lib/discourse_add_jobs_to_digest/user_notifications_helper_override"
  require_relative "lib/discourse_add_jobs_to_digest/engine"
  require_relative "lib/discourse_add_jobs_to_digest/job_api"

  require_dependency "user_notifications"
  module ::UserNotificationsHelperOverride
    def digest_custom_html(position_key)
      if position_key == "above_footer"
        # Custom HTML for the popular topics position
        DiscourseAddJobsToDigest::JobApi.get_jobs_html(@user)
      else
        super
      end
    end
  end

  UserNotificationsHelper.prepend(::UserNotificationsHelperOverride)

  module ::UserNotificationsOverride
    def digest(user, opts = {})
      # Custom logic for the digest
      @user = user
      super
    end
  end
  UserNotifications.prepend(::UserNotificationsOverride)
end

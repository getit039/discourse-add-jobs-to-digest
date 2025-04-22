# frozen_string_literal: true
require_dependency "user_notifications"
module ::UserNotificationsHelperOverride
  def digest_custom_html(position_key)
    puts "doing the digest: #{position_key}"
    super
  end
end

UserNotificationsHelper.prepend(::UserNotificationsHelperOverride)

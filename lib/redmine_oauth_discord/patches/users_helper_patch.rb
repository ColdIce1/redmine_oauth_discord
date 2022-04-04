require_dependency "users_helper"

module RedmineOauthDiscord
  module Patches
    module UsersHelperPatch
      def self.included(base) # :nodoc:
        base.send(:prepend, InstanceMethods)
      end

      module InstanceMethods
        def user_settings_tabs
          logger.debug("hello user_settings_tabs")
          tabs = super
          tabs << {
            :name => "discord_username_history", :partial => "users/users_tab", :label => :user_discord_username_history_tab,
          } if User.current.admin?
          tabs
        end
      end
    end
  end
end

unless UsersHelper.included_modules.include? RedmineOauthDiscord::Patches::UsersHelperPatch
  UsersHelper.send :include, RedmineOauthDiscord::Patches::UsersHelperPatch
end

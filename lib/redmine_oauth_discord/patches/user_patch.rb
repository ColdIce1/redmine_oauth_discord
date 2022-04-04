require_dependency "user"

module RedmineOauthDiscord
  module Patches
    module UserPatch
      def self.prepended(base)
        class << base
          self.prepend(InstanceMethods)
        end
        base.class_eval do
          unloadable
          const_set :USER_FORMATS,
                    {
                      :username_discorddiscriminator => {
                        :string => '#{User.format_discord_login(login)}',
                        :order => %w(login id),
                        :setting_order => 20,
                      },
                    }.merge(remove_const :USER_FORMATS)
          has_many :discord_username_history
        end
      end

      module InstanceMethods
        def format_discord_login(login)
          user = self.current
          unless user.discord_discriminator
            return "#{login}"
          else
            return "#{user.login}##{user.discord_discriminator.to_s.rjust(4, "0")}"
          end
        end
      end

      # disallow password change if this is a discord user
      def change_password_allowed?
        super && !discord_id?
      end

      # save username to audit username table
      def update_discord_name_history
        DiscordUsernameHistory.create!(:user_id => self.id, :username => self.login, :discriminator => self.discord_discriminator)
      end
    end
  end
end

User.prepend RedmineOauthDiscord::Patches::UserPatch

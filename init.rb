require 'redmine'
require_dependency 'redmine_oauth_discord/hooks'
require_dependency 'redmine_oauth_discord/my_controller_patch'

Redmine::Plugin.register :redmine_oauth_discord do
  name 'Redmine OAuth Discord plugin'
  author 'coldice'
  description 'Redmine Authentication using Discord as OAuth2 provider'
  version '0.1.0'
  url ''
  author_url ''

  settings default: {
             client_id: '',
             client_secret: '',
             oauth_authentification: false,
           },
           partial: 'settings/discord_settings'
end

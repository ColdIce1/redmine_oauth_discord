# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'oauth_discord', to: 'redmine_oauth#oauth_discord'
get 'oauth2callback',
    to: 'redmine_oauth#oauth_discord_callback',
    as: 'oauth_discord_callback'

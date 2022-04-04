# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'oauth_discord', to: 'redmine_oauth_discord#oauth_discord'
get 'oauth2callback',
    to: 'redmine_oauth_discord#oauth_discord_callback',
    as: 'oauth_discord_callback'
match 'account/discord_register', :to => 'redmine_oauth_discord#discord_register', :via => [:get, :post], :as => 'discord_register'
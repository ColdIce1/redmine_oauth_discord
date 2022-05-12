# Reedmine oauth Discord

This plugin is used to authenticate Redmine users using Discord as OAuth2 provider.

The major logic as similar as [redmine_oauth_engine](https://github.com/pwr-inf/redmine_oauth_engine)

## Installation

Download the plugin, install required gems and migrate to update the database:

```console
cd /path/to/redmine/plugins
git clone github_repo_url
cd /path/to/redmine
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Restart the app

```console
touch /path/to/redmine/tmp/restart.txt
```

You should now be able to see the plugin list in Administration -> Plugins and configure the newly installed plugin.

## Registration

To authenticate via Discord you must first register your redmine instance via the Discord Developer Portal

* Go to [Discord Developer Portal](https://discord.com/developers/)
* Register a new app, then navigate to OAuth2
* Add a new redirect: `http://mydomain.com/redmine/oauth2callback`  where "mydomain.com/redmine" is the domain / path for your redmine instance. ***The plugin will not work without this setting***
* Save the Client ID and Client Secret for the configuration of the Redmine plugin (see below)

## Configuration

* Login as a user with administrative privileges.
* In top menu select "Administration".
* Click "Plugins"
* In plugins list, click "Configure" in the row for "Redmine OAuth Discord plugin"
* Enter the Сlient ID & Client Secret shown when you registered your application via Dataporten Dashboard.
* Check the box near "Oauth authentication enabled"
* Click Apply.

Users can now to use their Discord Account to log in to your instance of Redmine.

Additionaly

* Setup value Autologin in Settings on tab Authentication

## Authentication Workflow

1. An unauthenticated user requests the URL to your Redmine instance.
2. User clicks the "Login via Discord" button.
3. The plugin redirects them to a Discord sign-in page if they are not already signed in to their Discord account.
4. Discord redirects user back to Redmine, where the Discord OAuth plugin's controller takes over.

Please note that this plugin does not care about "self-registration" status. It will always allow login UNLESS **Oauth authentication enabled** is unticked in the plugin settings page. If you want to revert this behaviour, see [redmine_oauth_discord_controller.rb](app/controllers/redmine_oauth_discord_controller.rb) line 61.

### Further info

Suggested reading [RFC6749 - The OAuth 2.0 Authorization Framework
](https://datatracker.ietf.org/doc/html/rfc6749)

Protocol Flow below

```text
     +--------+                               +---------------+
     |        |--(A)- Authorization Request ->|   Resource    |
     |        |                               |     Owner     |
     |        |<-(B)-- Authorization Grant ---|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(C)-- Authorization Grant -->| Authorization |
     | Client |                               |     Server    |
     |        |<-(D)----- Access Token -------|               |
     |        |                               +---------------+
     |        |
     |        |                               +---------------+
     |        |--(E)----- Access Token ------>|    Resource   |
     |        |                               |     Server    |
     |        |<-(F)--- Protected Resource ---|               |
     +--------+                               +---------------+
```

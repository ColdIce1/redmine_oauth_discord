class RedmineOauthController < AccountController
  def oauth_discord
    if Setting.plugin_redmine_oauth_discord[:oauth_authentification]
      state = SecureRandom.urlsafe_base64
      session[:back_url] = params[:back_url]
      session[:auth_state] = { value: state, expires: 2.minutes, secure: true }
      redirect_to oauth_client.auth_code.authorize_url(
                    redirect_uri: oauth_discord_callback_url,
                    scope: %w[identify email].join(' '),
                    state: state,
                  )
    else
      password_authentication
    end
  end

  def oauth_client
    @client ||=
      OAuth2::Client.new(
        settings[:client_id],
        settings[:client_secret],
        token_method: :post,
        site: 'https://discord.com',
        authorize_url: '/api/oauth2/authorize',
        token_url: '/api/oauth2/token',
      )
  end

  def oauth_discord_callback
    if (params[:state].nil?) || (session[:auth_state].nil?) ||
         (params[:state] != session[:auth_state][:value])
      flash[:error] = l(:notice_access_denied)
      redirect_to signin_path
    else
      token_response =
        oauth_client.auth_code.get_token(
          params[:code],
          redirect_uri: oauth_discord_callback_url,
        )
      result = token_response.get('https://discord.com/api/users/@me')
      info = JSON.parse(result.body)
      if info && info['email']
        try_to_login info, token_response
      else
        flash[:error] = l(:notice_unable_to_obtain_discord_credentials)
        redirect_to signin_path
      end
    end
  end

  def try_to_login(info, token)
    params[:back_url] = session[:back_url]
    session.delete(:back_url)
    user =
      User
        .joins(:email_addresses)
        .where(email_addresses: { address: info['email'] })
        .first_or_create
    if user.new_record?
      # Allow sign-in even when self-registration is off. Sign-in is instead controller by the plugin setting oauth_authentification
      #redirect_to(home_url) && return unless Setting.self_registration?

      # Create on the fly
      # Discord does not support firstname / lastname
      user.firstname = 'Discord'
      user.lastname = 'User'
      user.mail = info['email']
      user.login = info['username']
      user.random_password
      user.discord_id = info['id']
      user.discord_avatar_url =
        "https://cdn.discordapp.com/avatars/#{info['id']}/#{info['avatar']}.png"
      user.register

      #case Setting.self_registration
      #when '1'
      #  register_by_email_activation(user) { onthefly_creation_failed(user) }
      #when '3'
      #  register_automatically(user) { onthefly_creation_failed(user) }
      #else
      #  register_manually_by_administrator(user) do
      #    onthefly_creation_failed(user)
      #  end
      #end
      register_automatically(user) { onthefly_creation_failed(user) }
    else
      # Existing record
      if user.active?
        user.login = info['username']
        user.discord_id = info['id']
        user.discord_avatar_url =
          "https://cdn.discordapp.com/avatars/#{info['id']}/#{info['avatar']}.png"
        params[:autologin] = true
        successful_authentication(user)
      else
        logger.debug 'account_pending'
        account_pending(user)
      end
    end
  end

  def set_autologin_cookie(user)
    token = user.generate_autologin_token
    secure = Redmine::Configuration['autologin_cookie_secure']
    secure = request.ssl? if secure.nil?
    cookie_options = {
      value: token,
      expires: 7.days.from_now, # Discord token life
      path:
        (
          Redmine::Configuration['autologin_cookie_path'] ||
            RedmineApp::Application.config.relative_url_root || '/'
        ),
      same_site: :lax,
      secure: secure,
      httponly: true,
    }
    cookies[autologin_cookie_name] = cookie_options
  end

  def settings
    @settings ||= Setting.plugin_redmine_oauth_discord
  end
end

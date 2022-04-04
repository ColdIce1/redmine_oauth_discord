class RedmineOauthDiscordController < AccountController
  def oauth_discord
    session[:auth_source_registration] = nil
    if Setting.plugin_redmine_oauth_discord[:oauth_authentification]
      state = SecureRandom.urlsafe_base64
      session[:back_url] = params[:back_url]
      session[:auth_state] = { value: state, expires: 2.minutes, secure: true }
      redirect_to oauth_client.auth_code.authorize_url(
                    redirect_uri: oauth_discord_callback_url,
                    scope: %w[identify].join(" "),
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
        site: "https://discord.com",
        authorize_url: "/api/oauth2/authorize",
        token_url: "/api/oauth2/token",
      )
  end

  def oauth_discord_callback
    if (params[:state].nil?) || (session[:auth_state].nil?) ||
       (params[:state] != session[:auth_state][:value])
      flash[:error] = l(:notice_discord_access_denied)
      redirect_to signin_path
    else
      if params[:code].present?
        begin
          token_response =
            oauth_client.auth_code.get_token(
              params[:code],
              redirect_uri: oauth_discord_callback_url,
            )
          userinfo = token_response.get("https://discord.com/api/users/@me").parsed
          try_to_login userinfo, token_response
        rescue OAuth2::Error => e
          flash[:error] = e.response.parsed["error_description"]
          redirect_to signin_path
        end
      else
        flash[:error] = l(:notice_unable_to_obtain_discord_credentials)
        redirect_to signin_path
      end
    end
  end

  def try_to_login(userinfo, token)
    params[:back_url] = session[:back_url]
    session.delete(:back_url)

    @user = User.where({ discord_id: userinfo["id"] }).first_or_create
    if @user.new_record?
      session[:oauth_last_seen] = Time.now
      # Allow sign-in even when self-registration is off. Sign-in is instead controller by the plugin setting oauth_authentification
      #redirect_to(home_url) && return unless Setting.self_registration?

      # set some params that we need for registering the user
      session[:auth_source_registration] = {
        :login => userinfo["username"],
        :auth_source_id => userinfo["id"],
        :discord_discriminator => userinfo["discriminator"],
        :discord_avatar_url => "https://cdn.discordapp.com/avatars/#{userinfo["id"]}/#{userinfo["avatar"]}.png",
      }

      # user needs to enter email before proceeding
      redirect_to discord_register_path
    else
      # Existing record
      if @user.active?
        # allow for auditing username changes
        if (userinfo["username"] != @user.login || userinfo["discriminator"] != @user.discord_discriminator)
          # update username & discriminator
          @user.login = userinfo["username"]
          @user.discord_discriminator = userinfo["discriminator"]
          @user.update_discord_name_history
        end

        @user.discord_avatar_url = "https://cdn.discordapp.com/avatars/#{userinfo["id"]}/#{userinfo["avatar"]}.png"
        if @user.save
          @user.update_last_login_on!
          params[:autologin] = true
          successful_authentication(@user)
        else
          flash[:error] = l(:notice_unable_to_login_via_discord)
          redirect_to signin_path
        end
      else
        if @user.registered?
          account_pending(@user)
        else
          account_locked(@user)
        end
      end
    end
  end

  # register the discord user in the system
  def discord_register
    (redirect_to(home_url); return) unless session[:auth_source_registration]
    # time-out registrations that began > 10 minutes ago
    if ((session[:oauth_last_seen] && session[:oauth_last_seen] < 10.minutes.ago) || !session[:oauth_last_seen])
      flash[:error] = l(:notice_unable_to_obtain_discord_credentials)
      redirect_to signin_path
    end

    if !request.post?
      # show HTML form 'discord_register.html.erb' if this is a get request
      @user = User.new(:language => current_language.to_s)
    else
      # user clicked submitt, validate request
      user_params = params[:user] || {}
      @user = User.new
      @user.safe_attributes = user_params
      @user.pref.safe_attributes = params[:pref]
      @user.admin = false
      @user.activate

      # discord does not have a first + last name
      @user.firstname = "Discord"
      @user.lastname = "User"

      # get the unique discord details and save it with the profile
      @user.login = session[:auth_source_registration][:login]
      @user.auth_source_id = session[:auth_source_registration][:auth_source_id]
      @user.discord_id = session[:auth_source_registration][:auth_source_id]
      @user.discord_discriminator = session[:auth_source_registration][:discord_discriminator]
      @user.discord_avatar_url = session[:auth_source_registration][:discord_avatar_url]

      if @user.save
        # add user to default group set by admin
        @group = Group.find(settings["default_group_id"].to_i)
        @group.users << @user
        @user.reload

        session[:oauth_last_seen] = nil
        session[:auth_source_registration] = nil
        self.logged_user = @user
        flash[:notice] = l(:notice_discord_account_created)
        redirect_to my_account_path
      end
    end
  end

  def set_autologin_cookie(user)
    token = user.generate_autologin_token
    secure = Redmine::Configuration["autologin_cookie_secure"]
    secure = request.ssl? if secure.nil?
    cookie_options = {
      value: token,
      expires: 7.days.from_now, # Discord token life
      path: (Redmine::Configuration["autologin_cookie_path"] ||
             RedmineApp::Application.config.relative_url_root || "/"),
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

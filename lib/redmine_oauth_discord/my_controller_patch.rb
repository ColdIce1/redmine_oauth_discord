module RedmineOauthDiscord
  module MyControllerPatch
    def account
      @user = User.current
      @pref = @user.pref
      if request.put?
        # disable editing of user information
        # if discord user
        unless @user.discord_id.nil?
          @user.safe_attributes =
            params[:user].except('firstname', 'lastname', 'mail')
        else
          @user.safe_attributes = params[:user]
        end

        @user.pref.safe_attributes = params[:pref]

        if @user.save
          @user.pref.save
          set_language_if_valid @user.language
          respond_to do |format|
            format.html do
              flash[:notice] = l(:notice_account_updated)
              redirect_to my_account_path
            end
            format.api { render_api_ok }
          end
          return
        else
          respond_to do |format|
            format.html { render action: :account }
            format.api { render_validation_errors(@user) }
          end
        end
      end
    end
  end
end

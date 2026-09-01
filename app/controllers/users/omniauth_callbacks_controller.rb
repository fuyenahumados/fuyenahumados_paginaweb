class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    autenticar_con_omniauth
  end

  def facebook
    autenticar_con_omniauth
  end

  def failure
    redirect_to new_user_session_path
  end

  private

  def autenticar_con_omniauth
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user&.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      redirect_to new_user_session_path
    end
  end
end

class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    account = ::Account.from_omniauth(auth)
    account_authorized(account)
    redirect_to after_bookingsync_sign_in_path, notice: "Signed in!"
  end

  def destroy
    clear_authorization!
    redirect_to after_bookingsync_sign_out_path, notice: "Signed out"
  end

  def failure
    response.headers['X-Frame-Options'] = '' if BookingSync::Engine.embedded
    @error_message = params[:message].try(:humanize)
  end
end

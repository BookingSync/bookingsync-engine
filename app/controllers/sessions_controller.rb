class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    account = BookingSyncEngine.account_model.from_omniauth(auth, request.host)
    account_authorized(account)
    redirect_to after_bookingsync_sign_in_path
  end

  def destroy
    clear_authorization!
    redirect_to after_bookingsync_sign_out_path
  end

  def failure
    allow_bookingsync_iframe
    @error_message = params[:message].try(:humanize)
  end
end

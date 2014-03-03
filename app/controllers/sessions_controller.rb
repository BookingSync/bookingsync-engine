class SessionsController < ApplicationController
  def create
    auth = request.env["omniauth.auth"]
    account = ::Account.from_omniauth(auth)
    session[:account_id] = account.id
    redirect_to after_bookingsync_sign_in_path, notice: "Signed in!"
  end

  def destroy
    session[:account_id] = nil
    redirect_to after_bookingsync_sign_out_path, notice: "Signed out"
  end
end

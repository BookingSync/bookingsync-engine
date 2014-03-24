module BookingSync::Engine::AuthHelpers
  extend ActiveSupport::Concern

  included do
    rescue_from OAuth2::Error, with: :handle_oauth_error
    rescue_from BookingSync::API::Unauthorized, with: :reset_authorization!
    helper_method :current_account
  end

  private

  # @return [Account, nil] currently authorized Account or nil if unauthorized
  def current_account
    @current_account ||= ::Account.find_by(uid: session[:account_id]) if session[:account_id].present?
  end

  # Callback after account is authorized.
  #
  # Stores the authorized account's uid in the session.
  #
  # @param account [Account] the just authorized account
  def account_authorized(account)
    session[:account_id] = account.uid.to_s
  end

  # Clear authorization if the account passed from the BookingSync app store
  # embed doesn't match the currently authorized account
  def enforce_requested_account_authorized!
    clear_authorization! unless requested_account_authorized?
  end

  # Checks if the account requested from the BookingSync app store embed
  # matches currently authorized account.
  def requested_account_authorized?
    session[:_bookingsync_account_id].blank? ||
      session[:_bookingsync_account_id] == session[:account_id]
  end

  # Removes the authorization from session. Will not redirect to any other
  # page, see {#reset_authorization!}
  def clear_authorization!
    session[:account_id] = nil
  end

  # Removes authorization from session and requests new authorization.
  # For removing authorization without redirecting, see {#clear_authorization!}.
  def reset_authorization!
    session[:_bookingsync_account_id] =
      params[:account_id].presence || session[:account_id]
    clear_authorization!
    request_authorization!
  end

  def request_authorization!
    redirect_to "/auth/bookingsync"
  end

  # Handler to rescue OAuth errors
  #
  # @param error [OAuth2::Error] the rescued error
  def handle_oauth_error(error)
    if error.code == "Not authorized"
      current_account.try(:clear_token!)
      reset_authorization!
    else
      raise
    end
  end

  # Path to which the user should be redirected after successful authorization.
  # This method should be overridden in applications using this engine.
  #
  # Defaults to root_path.
  def after_bookingsync_sign_in_path
    root_path
  end

  # Path to which the user should be redirected after sign out.
  # This method should be overridden in applications using this engine.
  #
  # Defaults to root_path.
  def after_bookingsync_sign_out_path
    root_path
  end

  # Requests authorization if not currently authorized.
  def authenticate_account!
    store_bookingsync_account_id
    sign_out_if_inactive
    enforce_requested_account_authorized!
    request_authorization! unless current_account
  end

  def store_bookingsync_account_id # :nodoc:
    return unless BookingSync::Engine.embedded
    session[:_bookingsync_account_id] = params.delete(:_bookingsync_account_id)
  end
end

require "repost"

module BookingSync::Engine::AuthHelpers
  extend ActiveSupport::Concern

  included do
    rescue_from OAuth2::Error, with: :handle_oauth_error
    rescue_from BookingSync::API::Unauthorized, with: :reset_authorization!
    if respond_to?(:helper_method)
      helper_method :current_account
    end
  end

  private

  # @return [Account, nil] currently authorized Account or nil if unauthorized
  def current_account
    return if session[:account_id].nil?

    @current_account ||=
      ::BookingSyncEngine.account_model.find_by_host_and_bookingsync_id_key(request.host, session[:account_id])
  end

  # Callback after account is authorized.
  #
  # Stores the authorized account's synced_id in the session.
  #
  # @param account [Account] the just authorized account
  def account_authorized(account)
    session[:account_id] = account.public_send(BookingSyncEngine.bookingsync_id_key).to_s
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

  # Request a new authorization.
  def request_authorization!
    respond_to do |format|
      format.html do
        if request.xhr?
          request_authorization_for_xhr!
        elsif BookingSync::Engine.embedded
          request_authorization_for_embedded!
        else
          request_authorization_for_standalone!
        end
      end

      format.json do
        head :unauthorized
      end
    end
  end

  # Request a new authorization for Ajax requests.
  #
  # Renders the new auto submit form with 401 Unauthorized status by default.
  def request_authorization_for_xhr!
    render html: auto_submit_form_html, status: :unauthorized
  end

  # Request a new authorization for Embedded Apps.
  #
  # Load the new authorization path using Javascript by default.
  def request_authorization_for_embedded!
    allow_bookingsync_iframe
    render html: auto_submit_form_html
  end

  # Request a new authorization for Standalone Apps.
  #
  # Redirects to new authorization path by default.
  def request_authorization_for_standalone!
    render html: auto_submit_form_html
  end

  # Path which will be used in POST request to start a new
  # Authorization process.
  #
  # Default to /auth/bookingsync
  NEW_AUTHORIZATION_URL = "/auth/bookingsync".freeze
  def new_authorization_path
    NEW_AUTHORIZATION_URL
  end

  def new_authorization_url
    request.base_url + new_authorization_path
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
    store_bookingsync_account_id if BookingSync::Engine.embedded
    sign_out_if_inactive
    enforce_requested_account_authorized!
    request_authorization! if current_account.nil?
  end

  def store_bookingsync_account_id # :nodoc:
    session[:_bookingsync_account_id] = params.delete(:_bookingsync_account_id)
  end

  def auto_submit_form_html
    Repost::Senpai.perform(
      new_authorization_path,
      params: { account_id: session[:_bookingsync_account_id] },
      options: { authenticity_token: Rack::Protection::AuthenticityToken.token(session) }
    ).html_safe
  end
end

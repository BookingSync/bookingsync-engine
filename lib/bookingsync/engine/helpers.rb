module BookingSync::Engine::Helpers
  extend ActiveSupport::Concern
  included do
    before_action :store_bookingsync_account_id, :enforce_account_id,
      :sign_out_if_inactive
    helper_method :current_account
    rescue_from OAuth2::Error, with: :handle_oauth_error
    rescue_from BookingSync::API::Unauthorized, with: :reset_authorization!
  end

  private

  def sign_out_if_inactive
    return unless BookingSync::Engine.embedded

    last_visit = session[:_bookingsync_last_visit]
    session[:_bookingsync_last_visit] = Time.now.to_i

    if last_visit && (Time.now.to_i - last_visit > BookingSync::Engine.sign_out_after)
      clear_account_id_authorization!
      redirect_to "/auth/bookingsync"
    end
  end

  def store_bookingsync_account_id
    session[:_bookingsync_account_id] = params.delete(:_bookingsync_account_id)
  end

  def after_bookingsync_sign_in_path
    root_path
  end

  def after_bookingsync_sign_out_path
    root_path
  end

  def handle_oauth_error(error)
    if error.code == "Not authorized"
      current_account.try(:clear_token!)
      reset_authorization!
    else
      raise
    end
  end

  def reset_authorization!
    session[:_bookingsync_account_id] =
      params[:account_id].presence || session[:account_id]
    clear_account_id_authorization!
    redirect_to "/auth/bookingsync"
  end

  def current_account
    @current_account ||= ::Account.find_by(uid: session[:account_id]) if session[:account_id].present?
  end

  def account_id_authorized!(account_id)
    session[:account_id] = account_id.to_i
    session[:authorized_account_ids] ||= []
    unless account_id_authorized?(account_id)
      session[:authorized_account_ids] << account_id.to_i
    end
  end

  def clear_account_id_authorization!
    session[:account_id] = nil
    session[:authorized_account_ids] = []
  end

  def account_id_authorized?(account_id)
    session[:authorized_account_ids] ||= []
    session[:authorized_account_ids].include? account_id.to_i
  end

  def enforce_account_id
    bookingsync_account_id = session[:_bookingsync_account_id]
    if bookingsync_account_id.present?
      if account_id_authorized?(bookingsync_account_id)
        session[:account_id] = bookingsync_account_id
      else
        session[:account_id] = nil
      end
    end
  end

  def allow_bookingsync_iframe
    response.headers['X-Frame-Options'] = ''
  end

  def current_account_token
    @current_account_token ||= begin
      token_options = {}
      if current_account.oauth_refresh_token
        token_options[:refresh_token] = current_account.oauth_refresh_token
        token_options[:expires_at]    = current_account.oauth_expires_at
      end

      token = OAuth2::AccessToken.new(BookingSync::Engine.oauth_client,
        current_account.oauth_access_token, token_options)

      if token.expired?
        token = token.refresh!
        current_account.update_token!(token)
      end

      token
    end
  end

  def application_token
    token = Thread.current[:_bookingsync_application_token]
    if token.nil? || token.expired?
      token = Thread.current[:_bookingsync_application_token] =
        BookingSync::Engine.application_token
    end
    token
  end
end

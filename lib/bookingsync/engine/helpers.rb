module BookingSync::Engine::Helpers
  extend ActiveSupport::Concern
  # helper_method :current_account
  included do
    helper_method :current_account
    rescue_from OAuth2::Error, with: :handle_oauth_error
  end

  private

  def handle_oauth_error(error)
    if error.code == "Not authorized"
      if current_account
        current_account.clear_token!
        session[:account_id] = nil
        redirect_to "/auth/bookingsync"
      end
    else
      raise
    end
  end

  def current_account
    @current_account ||= ::Account.find(session[:account_id]) if session[:account_id]
  end

  def current_account_token
    @current_account_token ||= begin
      token_options = {}
      if current_account.oauth_refresh_token
        token_options[:refresh_token] = current_account.oauth_refresh_token
        token_options[:expires_at]    = current_account.oauth_expires_at
      end

      token = OAuth2::AccessToken.new(oauth_client,
        current_account.oauth_access_token, token_options)

      if token.expired?
        token = token.refresh!
        current_account.update_token!(token)
      end

      token
    end
  end

  def application_token
    @application_token ||= oauth_client.client_credentials.get_token
  end

  def oauth_client
    client_options = {
      site: ENV['BOOKINGSYNC_URL'] || 'https://www.bookingsync.com',
      connection_opts: {headers: {accept: "application/vnd.api+json"}}
    }
    client_options[:ssl] = {verify: false} if Rails.env.development?
    OAuth2::Client.new(ENV['BOOKINGSYNC_APP_ID'], ENV['BOOKINGSYNC_APP_SECRET'],
      client_options)
  end
end

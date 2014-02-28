module BookingSync::Engine::Helpers
  extend ActiveSupport::Concern
  # helper_method :current_account
  included do
    helper_method :current_account
  end

  private

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
      connection_opts: { headers: { accept: "application/vnd.api+json" } }
    }
    if Rails.env.development? || Rails.env.test?
      client_options[:ssl] = { verify: (ENV['BOOKINGSYNC_VERIFY_SSL'] || false) }
    end
    OAuth2::Client.new(ENV['BOOKINGSYNC_APP_ID'], ENV['BOOKINGSYNC_APP_SECRET'],
      client_options)
  end
end

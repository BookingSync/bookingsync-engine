module BookingSync::Engine::Model
  extend ActiveSupport::Concern

  module ClassMethods
    def from_omniauth(auth)
      where(auth.slice(:provider, :uid)).first_or_initialize.tap do |account|
        account.provider  = auth.provider
        account.uid       = auth.uid
        account.name      = auth.info.business_name

        account.update_token(auth.credentials)

        account.save!
      end
    end
  end

  def token
    @token ||= begin
      token_options = {}
      if oauth_refresh_token
        token_options[:refresh_token] = oauth_refresh_token
        token_options[:expires_at]    = oauth_expires_at
      end

      token = OAuth2::AccessToken.new(BookingSync::Engine.oauth_client,
        oauth_access_token, token_options)

      if token.expired?
        token = token.refresh!
        update_token!(token)
      end

      token
    end
  end

  def api
    @api ||= BookingSync::API::Client.new(token.token)
  end

  def update_token(token)
    self.oauth_access_token   = token.token
    self.oauth_refresh_token  = token.refresh_token
    self.oauth_expires_at     = token.expires_at
  end

  def update_token!(token)
    update_token(token)
    save!
  end

  def clear_token!
    self.oauth_access_token   = nil
    self.oauth_refresh_token  = nil
    self.oauth_expires_at     = nil
    save!
  end
end

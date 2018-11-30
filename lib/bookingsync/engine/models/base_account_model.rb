module BookingSync::Engine::Models::BaseAccountModel
  extend ActiveSupport::Concern

  included do
    scope :authorized, -> { where.not(oauth_access_token: nil) }
  end

  def token
    @token ||= begin
      token_options = {}
      if oauth_refresh_token
        token_options[:refresh_token] = oauth_refresh_token
        token_options[:expires_at]    = oauth_expires_at
      end

      token = OAuth2::AccessToken.new(oauth_client, oauth_access_token, token_options)

      if token.expired?
        refresh_token!(token)
      else
        token
      end
    end
  end

  def api
    @api ||= BookingSync::Engine::APIClient.new(token.token, account: self)
  end

  def clear_token!
    self.oauth_access_token   = nil
    self.oauth_refresh_token  = nil
    self.oauth_expires_at     = nil
    save!
  end

  def update_token(token)
    self.oauth_access_token   = token.token
    self.oauth_refresh_token  = token.refresh_token
    self.oauth_expires_at     = token.expires_at
  end

  private

  def refresh_token!(current_token = token)
    @token = current_token.refresh!.tap { |new_token| update_token!(new_token) }
  end

  def update_token!(token)
    update_token(token)
    save!
  end
end

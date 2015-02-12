module BookingSync::Engine::Model
  extend ActiveSupport::Concern

  included do
    validates :uid, uniqueness: true
    scope :authorized, -> { where.not(oauth_access_token: nil) }
  end

  module ClassMethods
    def from_omniauth(auth)
      find_or_initialize_by(uid: auth.uid, provider: auth.provider).tap do |account|
        account.name = auth.info.business_name
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
        refresh_token!
      else
        token
      end
    end
  end

  def refresh_token!
    @token = token.refresh!.tap { |new_token| update_token!(new_token) }
  end

  def api
    @api ||= BookingSync::Engine::APIClient.new(token.token, account: self)
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

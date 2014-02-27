class Account < ActiveRecord::Base
  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |account|
      account.provider = auth.provider
      account.uid = auth.uid
      account.name = auth.info.business_name

      account.update_token(auth.credentials)

      account.save!
    end
  end

  def update_token(token)
    self.oauth_access_token = token.token
    self.oauth_refresh_token = token.refresh_token
    self.oauth_expires_at = token.expires_at
  end

  def update_token!(token)
    update_token(token)
    save!
  end
end

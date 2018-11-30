module BookingSync::Engine::Models::SingleApplicationAccountModel
  extend ActiveSupport::Concern
  include BookingSync::Engine::Models::BaseAccountModel

  included do
    validates :synced_id, uniqueness: true
  end

  module ClassMethods
    def from_omniauth(auth, host)
      account = find_or_initialize_by(synced_id: auth.uid, provider: auth.provider)

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end
  end

  def application_token
    BookingSync::Engine.application_token
  end

  def oauth_client
    BookingSync::Engine.oauth_client
  end

  def application
    nil
  end
end

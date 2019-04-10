module BookingSync::Engine::Models::Account
  extend ActiveSupport::Concern
  include BookingSync::Engine::Models::BaseAccount

  included do
    validates :synced_id, uniqueness: true
  end

  module ClassMethods
    def from_omniauth(auth, _host)
      account = find_or_initialize_by(synced_id: auth.uid, provider: auth.provider)

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end

    def find_by_host_and_synced_id(_host, synced_id)
      find_by(synced_id: synced_id)
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

module BookingSync::Engine::Models::MultiApplicationsAccountModel
  extend ActiveSupport::Concern
  include BookingSync::Engine::Models::BaseAccountModel

  included do
    validates :synced_id, uniqueness: { scope: :host }
  end

  module ClassMethods
    def from_omniauth(auth, host)
      if host.blank?
        raise ArgumentError, "The `host` variable must be passed when using BookingSync Engine with " \
                             "multi application support"
      end

      account = find_or_initialize_by(host: host, synced_id: auth.uid, provider: auth.provider)

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end
  end

  def application_token
    BookingSync::Engine.application_token(
      client_id: application.client_id,
      client_secret: application.client_secret
    )
  end

  def oauth_client
    BookingSync::Engine.oauth_client(
      client_id: application.client_id,
      client_secret: application.client_secret
    )
  end

  def application
    @application ||= Application.find_by_host(host)
  end
end

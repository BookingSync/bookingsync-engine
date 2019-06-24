module BookingSync::Engine::Models::MultiApplicationsAccount
  extend ActiveSupport::Concern
  include BookingSync::Engine::Models::BaseAccount

  included do
    validates BookingSyncEngine.bookingsync_id_key, uniqueness: { scope: :host }
  end

  module ClassMethods
    def from_omniauth(auth, host)
      if host.blank?
        raise ArgumentError, "The `host` variable must be passed when using BookingSync Engine with " \
                             "multi application support"
      end

      account = find_or_initialize_by(host: host, provider: auth.provider, BookingSyncEngine.bookingsync_id_key => auth.uid)

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end

    def find_by_host_and_bookingsync_id_key(host, bookingsync_id)
      find_by(host: host, BookingSyncEngine.bookingsync_id_key => bookingsync_id)
    end

    # DEPRECATED: Please use find_by_host_and_bookingsync_id_key instead.
    def find_by_host_and_synced_id(host, synced_id)
      warn("DEPRECATED: find_by_host_and_synced_id is deprecated, use #find_by_host_and_bookingsync_id_key instead. It will be removed with the release of version 5 of this gem. Called from #{Gem.location_of_caller.join(":")}")
      find_by_host_and_bookingsync_id_key(host, synced_id)
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

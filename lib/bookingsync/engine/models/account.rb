module BookingSync::Engine::Models::Account
  extend ActiveSupport::Concern
  include BookingSync::Engine::Models::BaseAccount

  included do
    validates BookingSyncEngine.bookingsync_id_key, uniqueness: true
  end

  module ClassMethods
    def from_omniauth(auth, _host)
      account = find_or_initialize_by(BookingSyncEngine.bookingsync_id_key => auth.uid, provider: auth.provider)

      account.tap do |account|
        account.name = auth.info.business_name
        account.update_token(auth.credentials)
        account.save!
      end
    end

    def find_by_host_and_bookingsync_id_key(_host, bookingsync_id)
      find_by(BookingSyncEngine.bookingsync_id_key => bookingsync_id)
    end

    # DEPRECATED: Please use find_by_host_and_bookingsync_id_key instead.
    def find_by_host_and_synced_id(_host, synced_id)
      warn("DEPRECATED: find_by_host_and_synced_id is deprecated, use #find_by_host_and_bookingsync_id_key instead. It will be removed with the release of version 5 of this gem. Called from #{Gem.location_of_caller.join(":")}")
      find_by_host_and_bookingsync_id_key(nil, synced_id)
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

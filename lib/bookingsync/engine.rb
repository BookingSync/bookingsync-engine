require 'omniauth'
require 'omniauth-bookingsync'
require 'bookingsync-api'

module BookingSync
  class Engine < ::Rails::Engine
    initializer "bookingsync.add_omniauth" do |app|
      app.middleware.use OmniAuth::Builder do
        provider :bookingsync,
          ENV['BOOKINGSYNC_APP_ID'],
          ENV['BOOKINGSYNC_APP_SECRET'],
          setup: -> (env) {
            if url = ENV['BOOKINGSYNC_URL']
              env['omniauth.strategy'].options[:client_options].site = url
            end
            if Rails.env.development? || Rails.env.test?
              env['omniauth.strategy'].options[:client_options].ssl = {
                verify: ENV['BOOKINGSYNC_VERIFY_SSL'] == 'true'
              }
            end
          }
      end
    end

    initializer "bookingsync.controller_helper" do |app|
      require "bookingsync/engine/helpers"
      require "bookingsync/engine/session_helpers"
      require "bookingsync/engine/auth_helpers"
      require "bookingsync/engine/token_helpers"

      ActiveSupport.on_load :action_controller do
        include BookingSync::Engine::Helpers
        include BookingSync::Engine::SessionHelpers
        include BookingSync::Engine::AuthHelpers
        include BookingSync::Engine::TokenHelpers
      end
    end

    # @return [Boolean]
    cattr_accessor :embedded
    self.embedded = true

    # Duration of inactivity after which the authorization will be reset.
    # See {BookingSync::Engine::SessionHelpers#sign_out_if_inactive}.
    # @return [Fixnum]
    cattr_accessor :sign_out_after
    self.sign_out_after = 10.minutes

    # Set the engine into embedded mode.
    #
    # Embedded apps are loaded from within the BookingSync app store, and
    # have a different method to redirect during the OAuth authorization
    # process. <b>This method will not work when the app is not embedded</b>.
    def self.embedded!
      self.embedded = true
    end

    # Set the engine into standalone mode.
    #
    # This setting is requried for the applications using this Engine
    # to work outside of the BookingSync app store.
    #
    # Restores the normal mode of redirecting during OAuth authorization.
    def self.standalone!
      self.embedded = false
    end

    # OAuth client configured for the application.
    #
    # The ENV variables used for configuration are described in {file:README.md}.
    #
    # @return [OAuth2::Client] configured OAuth client
    def self.oauth_client
      client_options = {
        site: ENV['BOOKINGSYNC_URL'] || 'https://www.bookingsync.com',
        connection_opts: { headers: { accept: "application/vnd.api+json" } }
      }
      if Rails.env.development? || Rails.env.test?
        client_options[:ssl] = { verify: ENV['BOOKINGSYNC_VERIFY_SSL'] == 'true' }
      end
      OAuth2::Client.new(ENV['BOOKINGSYNC_APP_ID'], ENV['BOOKINGSYNC_APP_SECRET'],
        client_options)
    end

    def self.application_token
      oauth_client.client_credentials.get_token
    end
  end
end

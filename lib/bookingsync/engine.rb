require "omniauth"
require "omniauth-bookingsync"
require "bookingsync-api"

module BookingSync
  class Engine < ::Rails::Engine
    initializer "bookingsync.add_omniauth" do |app|
      app.middleware.use OmniAuth::Builder do
        provider :bookingsync,
          BookingSyncEngine.support_multi_applications? ? nil : ENV["BOOKINGSYNC_APP_ID"],
          BookingSyncEngine.support_multi_applications? ? nil : ENV["BOOKINGSYNC_APP_SECRET"],
          scope: ENV["BOOKINGSYNC_SCOPE"],
          setup: -> (env) {
            if url = ENV["BOOKINGSYNC_URL"]
              env["omniauth.strategy"].options[:client_options].site = url
            end
            env["omniauth.strategy"].options[:client_options].ssl = {
              verify: ENV["BOOKINGSYNC_VERIFY_SSL"] != "false"
            }

            if BookingSyncEngine.support_multi_applications?
              credentials = BookingSync::Engine::CredentialsResolver.new(env["HTTP_HOST"]).call
              if credentials.valid?
                env["omniauth.strategy"].options[:client_id] = credentials.client_id
                env["omniauth.strategy"].options[:client_secret] = credentials.client_secret
              end
            end
          }
      end
    end

    initializer "bookingsync.controller_helper" do |app|
      require "bookingsync/engine/helpers"
      require "bookingsync/engine/session_helpers"
      require "bookingsync/engine/auth_helpers"

      ActiveSupport.on_load :action_controller do
        include BookingSync::Engine::Helpers
        include BookingSync::Engine::SessionHelpers
        include BookingSync::Engine::AuthHelpers
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
    def self.oauth_client(client_id: ENV["BOOKINGSYNC_APP_ID"], client_secret: ENV["BOOKINGSYNC_APP_SECRET"])
      client_options = {
        site: ENV["BOOKINGSYNC_URL"] || 'https://www.bookingsync.com',
        connection_opts: { headers: { accept: "application/vnd.api+json" } }
      }
      client_options[:ssl] = { verify: ENV['BOOKINGSYNC_VERIFY_SSL'] != 'false' }
      OAuth2::Client.new(client_id, client_secret, client_options)
    end

    def self.application_token(client_id: nil, client_secret: nil)
      oauth_client(client_id: client_id, client_secret: client_secret).client_credentials.get_token
    end
  end
end

require "bookingsync/engine/application_credentials"
require "bookingsync/engine/credentials_resolver"
require "bookingsync/engine/api_client"
require "bookingsync/engine/models"

require 'omniauth'
require 'omniauth-bookingsync'

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
            env['omniauth.strategy'].options[:client_options].ssl = {verify: false} if Rails.env.development?
          }
      end
    end

    initializer "bookingsync.controller_helper" do |app|
      require "bookingsync/engine/helpers"
      ActiveSupport.on_load :action_controller do
        include BookingSync::Engine::Helpers
      end
    end
  end
end

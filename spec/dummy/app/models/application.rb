class Application < ActiveRecord::Base
  include BookingSync::Engine::Models::Application
end

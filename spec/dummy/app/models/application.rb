class Application < ActiveRecord::Base
  include BookingSync::Engine::Models::ApplicationModel
end

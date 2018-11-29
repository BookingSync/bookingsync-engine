class Application < ActiveRecord::Base
  include BookingSync::Engine::ApplicationModel
end

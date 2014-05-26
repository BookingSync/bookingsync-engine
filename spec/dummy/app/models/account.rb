class Account < ActiveRecord::Base
  include BookingSync::Engine::Model
end

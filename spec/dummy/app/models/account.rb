class Account < ActiveRecord::Base
  include BookingSync::Engine::Models::Account
end

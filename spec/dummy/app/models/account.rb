class Account < ActiveRecord::Base
  include BookingSync::Engine::AccountModel
end

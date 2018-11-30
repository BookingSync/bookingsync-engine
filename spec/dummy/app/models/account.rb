class Account < ActiveRecord::Base
  include BookingSync::Engine::Models::SingleApplicationAccountModel
end

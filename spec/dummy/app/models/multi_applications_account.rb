class MultiApplicationsAccount < ActiveRecord::Base
  include BookingSync::Engine::Models::MultiApplicationsAccountModel
end

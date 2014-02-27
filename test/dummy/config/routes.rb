Rails.application.routes.draw do

  mount BookingSync::Engine => "/bookingsync"
end

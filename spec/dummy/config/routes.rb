Rails.application.routes.draw do
  mount BookingSync::Engine => '/'
  get "/authenticated", to: "authenticated#index"
  root to: "home#index"
end

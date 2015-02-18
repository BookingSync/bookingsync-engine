Rails.application.routes.draw do
  mount Bookingsync::Engine => '/'
  get "/authenticated", to: "authenticated#index"
  root to: "home#index"
end

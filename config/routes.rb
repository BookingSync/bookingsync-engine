Bookingsync::Engine.routes.draw do
  get '/auth/bookingsync/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/signout' => 'sessions#destroy', as: :signout
end

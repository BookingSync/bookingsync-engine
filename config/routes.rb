Rails.application.routes.draw do
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  get '/signout' => 'sessions#destroy', as: :signout
end

Rails.application.routes.draw do
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/signout' => 'sessions#destroy', as: :signout
end

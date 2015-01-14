require 'spec_helper'

describe 'oauth routing', type: :routing do
  routes { BookingSync::Engine.routes }
  it 'has a auth callback route' do
    expect(get: '/auth/facebook/callback').to route_to(controller: 'sessions',
      action: 'create', provider: 'facebook')
  end

  it 'has a auth failure route' do
    expect(get: '/auth/failure').to route_to(controller: 'sessions',
      action: 'failure')
  end

  it 'has a signout route' do
    expect(get: '/signout').to route_to(controller: 'sessions',
      action: 'destroy')
  end

  it 'has a signout named route', :inject_locale_to_routes do
    expect(get: signout_path).to route_to(controller: 'sessions',
      action: 'destroy')
  end
end

require 'spec_helper'

describe 'oauth routing', type: :routing do
  routes { Bookingsync::Engine.routes }
  it 'has a bookingsync auth callback route' do
    expect(get: '/auth/bookingsync/callback').to route_to(controller: 'sessions', action: 'create')
  end

  it "doesn't capture auth callback routes for other providers" do
    expect(get: '/auth/facebook/callback').to_not route_to(controller: 'sessions',
      action: 'create')
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

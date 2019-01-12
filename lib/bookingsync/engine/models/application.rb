module BookingSync::Engine::Models::Application
  extend ActiveSupport::Concern

  included do
    validates :host, presence: true, uniqueness: true
    validates :client_id, presence: true, uniqueness: true
    validates :client_secret, presence: true, uniqueness: true
  end
end

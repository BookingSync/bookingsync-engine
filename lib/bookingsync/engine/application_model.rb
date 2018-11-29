module BookingSync::Engine::ApplicationModel
  extend ActiveSupport::Concern

  included do
    validates :host, presence: true, uniqueness: true
    validates :client_id, presence: true
    validates :client_secret, presence: true
  end
end

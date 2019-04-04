require "bookingsync"

module BookingSyncEngine
  cattr_accessor :support_multi_applications
  self.support_multi_applications = false

  cattr_accessor :single_app_model
  self.single_app_model = -> { ::Account }

  cattr_accessor :multi_app_model
  self.multi_app_model = -> { ::Account }

  def self.setup
    yield self
  end

  def self.support_multi_applications?
    env_opt = ENV.fetch("BOOKINGSYNC_ENGINE_SUPPORT_MULTI_APPLICATIONS") { nil }
    if env_opt
      env_opt.to_s.downcase == "true"
    else
      support_multi_applications
    end
  end

  def self.setup_model
    support_multi_applications? ? multi_app_model.call : single_app_model.call
  end
end

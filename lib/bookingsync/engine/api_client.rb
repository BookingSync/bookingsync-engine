class BookingSync::Engine::APIClient < BookingSync::API::Client
  def initialize(token, options = {})
    super
    @account = options[:account]
  end

  def call(method, path, data = nil, options = nil)
    tries ||= 1
    super
  rescue BookingSync::API::Unauthorized => e
    token_expired = e.headers["www-authenticate"].include?("The access token expired")
    if token_expired && (tries -= 1) >= 0
      retry_on_timeout { @token = @account.refresh_token!.token }
      retry
    else
      raise
    end
  end

  # Temporary fix to investigate broken oauth tokens
  def retry_on_timeout
    tries ||= 0
    yield
  rescue Faraday::TimeoutError => e
    if (tries += 1) <= 3
      Rails.logger.error("[bookingsync-engine] Retry #{tries} Rescued #{e} for account: #{@account.id}")
      retry
    else
      Rails.logger.error("[bookingsync-engine] After #{tries} re-reising #{e} for account: #{@account.id}")
      raise
    end
  end
end

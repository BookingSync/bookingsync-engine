class BookingSync::Engine::Retryable
  def self.perform(times:, errors:, before_retry: ->(_error) {})
    executed = 0
    begin
      executed += 1
      yield
    rescue *errors => error
      if executed < times
        before_retry.call(error)
        retry
      else
        raise error
      end
    end
  end
end

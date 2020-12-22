require "spec_helper"

RSpec.describe BookingSync::Engine::Retryable do
  describe ".perform" do
    let(:before_retry) do
      Class.new do
        attr_reader :called, :errors

        def initialize
          @called = 0
          @errors = []
        end

        def call(error)
          @called += 1
          @errors << error
        end
      end.new
    end

    it "retries logic for given amount of times for given errors
    and raises original error if the number is exceeded" do
      times_executed = 0

      expect {
        BookingSync::Engine::Retryable.perform(times: 3, errors: [NotImplementedError]) do
          times_executed += 1
          raise NotImplementedError
        end
      }.to raise_error NotImplementedError

      expect(times_executed).to eq 3
    end

    it "calls before_retry callback before every retry" do
      expect {
        BookingSync::Engine::Retryable.perform(times: 3, errors: [NotImplementedError], before_retry: before_retry) do
          raise NotImplementedError
        end
      }.to raise_error NotImplementedError

      expect(before_retry.called).to eq 2
      expect(before_retry.errors.count).to eq 2
      expect(before_retry.errors.uniq.first).to be_a NotImplementedError
    end

    it "does not retry for given amount of times if it succeeds before exceeding given number" do
      times_executed = 0

      BookingSync::Engine::Retryable.perform(times: 3, errors: [NotImplementedError]) do
        times_executed += 1
        raise NotImplementedError if times_executed < 2
      end

      expect(times_executed).to eq 2
    end

    it "does not retry if no error is raised" do
      times_executed = 0

      BookingSync::Engine::Retryable.perform(times: 3, errors: [NotImplementedError]) do
        times_executed += 1
      end

      expect(times_executed).to eq 1
    end

    it "does not retry not whitelisted errors" do
      times_executed = 0

      expect {
        BookingSync::Engine::Retryable.perform(times: 3, errors: [LocalJumpError]) do
          times_executed += 1
          raise NotImplementedError
        end
      }.to raise_error NotImplementedError

      expect(times_executed).to eq 1
    end
  end
end

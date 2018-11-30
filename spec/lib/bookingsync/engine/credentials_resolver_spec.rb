require "spec_helper"

RSpec.describe BookingSync::Engine::CredentialsResolver do
  describe "#call" do
    let(:credentials_resolver) do
      BookingSync::Engine::CredentialsResolver.new("example.test")
    end
    let!(:application) do
      Application.create(host: "example.test", client_id: "123", client_secret: "456")
    end

    it "returns an application credentials properly initiated" do
      expect(BookingSync::Engine::ApplicationCredentials).to receive(:new)
        .with(application).and_return("great")
      expect(credentials_resolver.call).to eq "great"
    end
  end
end

require "spec_helper"

RSpec.describe BookingSync::Engine::ApplicationCredentials do
  describe "#valid" do
    context "with no application given" do
      subject(:application_credentials) { BookingSync::Engine::ApplicationCredentials.new }

      it "returns false" do
        expect(application_credentials.valid?).to eq false
      end
    end

    context "with application given" do
      subject(:application_credentials) { BookingSync::Engine::ApplicationCredentials.new(application) }

      context "with client_id missing" do
        let(:application) { Application.new(host: "exemple.test", client_id: nil, client_secret: "456") }

        it "returns false" do
          expect(application_credentials.valid?).to eq false
        end
      end

      context "with client_secret missing" do
        let(:application) { Application.new(host: "exemple.test", client_id: "123", client_secret: nil) }

        it "returns false" do
          expect(application_credentials.valid?).to eq false
        end
      end

      context "with client_id and client_secret present" do
        let(:application) { Application.new(host: "exemple.test", client_id: "123", client_secret: "456") }

        it "returns true" do
          expect(application_credentials.valid?).to eq true
        end
      end
    end
  end
end

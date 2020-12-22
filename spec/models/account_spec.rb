require "spec_helper"

RSpec.describe Account, type: :model do
  shared_examples "it takes attributes from auth" do
    it "sets name" do
      expect(account.name).to eq "business name"
    end

    it "sets token" do
      expect(account.oauth_access_token).to eql("token")
      expect(account.oauth_refresh_token).to eql("refresh token")
      expect(account.oauth_expires_at).to eql("expires at")
    end
  end

  describe "validations" do
    it { is_expected.to validate_uniqueness_of(:synced_id) }
  end

  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    before { Account.create!(provider: "bookingsync", synced_id: 456) }

    context "when account exists" do
      let!(:account) { Account.create!(provider: "bookingsync", synced_id: 123) }

      context "with host given" do
        it "loads the existing account" do
          expect(Account.from_omniauth(auth, "example.test")).to eql(account)
        end
      end

      context "without host given" do
        it "loads the existing account" do
          expect(Account.from_omniauth(auth, nil)).to eql(account)
        end
      end

      describe "the updated account" do
        before do
          Account.from_omniauth(auth, "example.test")
          account.reload
        end

        it_behaves_like "it takes attributes from auth"
      end
    end

    context "when account doesn't exist" do
      it "creates new account" do
        expect {
          Account.from_omniauth(auth, "example.test")
        }.to change { Account.count }.by(1)
      end

      describe "the newly created account" do
        let!(:account) { Account.from_omniauth(auth, "example.test") }

        it "sets synced_id and provider from auth" do
          expect(account.synced_id).to eq 123
          expect(account.provider).to eq "bookingsync"
        end

        it_behaves_like "it takes attributes from auth"
      end
    end
  end

  describe ".find_by_host_and_synced_id" do
    let!(:account_1) { Account.create!(synced_id: 1) }
    let!(:account_2) { Account.create!(synced_id: 2) }
    let!(:account_3) { Account.create!(synced_id: 3) }

    it "returns the right account" do
      expect(Account.find_by_host_and_synced_id("any_host", 3)).to eq account_3
    end
  end

  describe "#token" do
    let!(:account) { Account.create!(synced_id: 123, oauth_access_token: "token",
      oauth_refresh_token: "refresh_token", oauth_expires_at: expires_at) }

    context "when the stored token is fresh" do
      let(:expires_at) { 1.day.from_now.to_i }

      it "returns the token" do
        expect(account.token).to be_a OAuth2::AccessToken
        expect(account.token.token).to eq "token"
      end
    end

    context "when the stored token is expired" do
      around do |test_case|
        # comparing rails version, the use_transactional_fixtures only works pre 5
        if Rails::VERSION::MAJOR >= 5
          original_setup = self.use_transactional_tests
          self.use_transactional_tests = false
          test_case.run
          self.use_transactional_tests = original_setup
        else
          original_setup = self.use_transactional_fixtures
          self.use_transactional_fixtures = false
          test_case.run
          self.use_transactional_fixtures = original_setup
        end
      end

      let(:expires_at) { 1.day.ago.to_i.to_s }

      before do
        stub_request(:post, "https://some_url.com/oauth/token").with(
          body: {
            "client_id" => "some_client_id",
            "client_secret" => "some_client_secret",
            "grant_type" => "refresh_token",
            "refresh_token" => "refresh_token"
          },
          headers: {
            "Accept" => "application/vnd.api+json",
            "Content-Type" => "application/x-www-form-urlencoded"
          }
        ).to_return(
          status: 200,
          body: { "access_token": "refreshed_token" }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
      end

      it "refreshes the token" do
        expect(account.token).to be_a OAuth2::AccessToken
        expect(account.token.token).to eq "refreshed_token"
      end

      context "with refresh failing with timeout" do
        before do
          call_count = 0
          allow_any_instance_of(OAuth2::Client).to receive(:get_token).and_wrap_original do |m, *args|
            call_count += 1
            call_count < 3 ? raise(Faraday::TimeoutError) : m.call(*args)
          end
        end

        context "and retry works" do
          before do
            BookingSyncEngine.setup do |setup|
              setup.token_refresh_timeout_retry_count = 2
            end
          end

          it "retries as passed in config" do
            expect(account.token.token).to eq "refreshed_token"
          end
        end

        context "and retry doesn't help" do
          before do
            BookingSyncEngine.setup do |setup|
              setup.token_refresh_timeout_retry_count = 1
            end
          end

          it "raises error" do
            expect { account.token.token }.to raise_error(Faraday::TimeoutError)
          end
        end
      end
    end
  end

  describe "#application_token" do
    let!(:account) { Account.create!(synced_id: 123) }
    before do
      stub_request(:post, "https://some_url.com/oauth/token").with(
        body: {
          "client_id" => "some_client_id",
          "client_secret" => "some_client_secret",
          "grant_type"=>"client_credentials"
        },
        headers: {
          "Accept" => "application/vnd.api+json",
          "Content-Type" => "application/x-www-form-urlencoded"
        }
      ).to_return(
        status: 200,
        body: { "access_token": "the_access_token" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
    end

    it "returns a client credential token setup without default params" do
      expect(account.application_token.token).to eq "the_access_token"
    end

    context "with refresh failing with timeout" do
      before do
        call_count = 0
        allow_any_instance_of(OAuth2::Client).to receive(:get_token).and_wrap_original do |m, *args|
          call_count += 1
          call_count < 3 ? raise(Faraday::TimeoutError) : m.call(*args)
        end
      end

      context "and retry works" do
        before do
          BookingSyncEngine.setup do |setup|
            setup.token_refresh_timeout_retry_count = 2
          end
        end

        it "retries as passed in config" do
          expect(account.application_token.token).to eq "the_access_token"
        end
      end

      context "and retry doesn't help" do
        before do
          BookingSyncEngine.setup do |setup|
            setup.token_refresh_timeout_retry_count = 1
          end
        end

        it "raises error" do
          expect { account.application_token.token }.to raise_error(Faraday::TimeoutError)
        end
      end
    end
  end

  describe "#oauth_client" do
    let!(:account) { Account.create!(synced_id: 123) }

    it "returns a BookingSync::Engine.oauth_client setup without default params" do
      expect(account.oauth_client).to be_an OAuth2::Client
      expect(account.oauth_client.id).to eq "some_client_id"
      expect(account.oauth_client.secret).to eq "some_client_secret"
    end
  end

  describe "#application" do
    let!(:account) { Account.create!(synced_id: 123) }

    it "returns nil" do
      expect(account.application).to be_nil
    end
  end

  describe "#api" do
    let!(:account) { Account.new(oauth_access_token: "access_token") }

    it "returns API client initialized with OAuth token" do
      expect(account.api).to be_kind_of(BookingSync::API::Client)
      expect(account.api.token).to eq("access_token")
    end
  end

  describe "#clear_token!" do
    let!(:account) do
      Account.create!(oauth_access_token: "token", oauth_refresh_token: "refresh",
        oauth_expires_at: "expires")
    end
    it "clears token related fields on account" do
      expect { account.clear_token! }
        .to change { account.reload.oauth_access_token }.from("token").to(nil)
        .and change { account.oauth_refresh_token }.from("refresh").to(nil)
        .and change { account.oauth_expires_at }.from("expires").to(nil)
    end
  end

  describe "#update_token" do
    let!(:account) do
      Account.create!(oauth_access_token: "token", oauth_refresh_token: "refresh",
        oauth_expires_at: "expires")
    end
    let(:token) do
      double(token: "new_access_token", refresh_token: "new_refresh_token",
        expires_at: "new_expires_at")
    end

    it "updates the token related fields on account" do
      expect { account.update_token(token) }
        .to change { account.oauth_access_token }.from("token").to("new_access_token")
        .and change { account.oauth_refresh_token }.from("refresh").to("new_refresh_token")
        .and change { account.oauth_expires_at }.from("expires").to("new_expires_at")
    end
  end
end

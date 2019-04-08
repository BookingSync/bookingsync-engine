require "spec_helper"

RSpec.describe MultiApplicationsAccount, type: :model do
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
    let!(:account) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 123, host: "example.test")
    end

    it { is_expected.to validate_uniqueness_of(:synced_id).scoped_to(:host).case_insensitive }
  end

  describe ".from_omniauth" do
    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }
    let!(:account) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 123, host: "example.test")
    end
    let!(:account2) do
      MultiApplicationsAccount.create!(provider: "bookingsync", synced_id: 456, host: "example2.test")
    end

    context "without host given" do
      it "raises an error" do
        expect { MultiApplicationsAccount.from_omniauth(auth, nil) }.to raise_error(ArgumentError,
          "The `host` variable must be passed when using BookingSync Engine with multi application support")
      end
    end

    context "with host given" do
      context "when account exists" do
        it "loads the existing account" do
          expect(MultiApplicationsAccount.from_omniauth(auth, "example.test")).to eql(account)
        end

        describe "the updated account" do
          before do
            MultiApplicationsAccount.from_omniauth(auth, "example.test")
            account.reload
          end

          it_behaves_like "it takes attributes from auth"
        end
      end

      context "when account doesn't exist" do
        it "creates new account" do
          expect {
            MultiApplicationsAccount.from_omniauth(auth, "example3.test")
          }.to change { MultiApplicationsAccount.count }.by(1)
        end

        describe "the newly created account" do
          let!(:account) { MultiApplicationsAccount.from_omniauth(auth, "example3.test") }

          it "sets synced_id and provider from auth as well as host" do
            expect(account.synced_id).to eq 123
            expect(account.provider).to eq "bookingsync"
            expect(account.host).to eq "example3.test"
          end

          it_behaves_like "it takes attributes from auth"
        end
      end
    end
  end

  describe ".find_by_host_and_synced_id" do
    let!(:account_1) { MultiApplicationsAccount.create!(synced_id: 1, host: "example.test") }
    let!(:account_2) { MultiApplicationsAccount.create!(synced_id: 2, host: "example.test") }
    let!(:account_3) { MultiApplicationsAccount.create!(synced_id: 1, host: "example2.test") }
    let!(:account_4) { MultiApplicationsAccount.create!(synced_id: 2, host: "example2.test") }

    it "returns the right account" do
      expect(MultiApplicationsAccount.find_by_host_and_synced_id("example2.test", 1)).to eq account_3
    end
  end

  describe "#token" do

    let!(:account) do
      MultiApplicationsAccount.create!(
        synced_id: 123, host: "example.test",
        oauth_access_token: "token", oauth_refresh_token: "refresh_token",
        oauth_expires_at: expires_at
      )
    end
    let!(:application) { Application.create!(host: "example.test", client_id: "123", client_secret: "456") }

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
          orinal_setup = self.use_transactional_tests
          self.use_transactional_tests = false
          test_case.run
          self.use_transactional_tests = orinal_setup
        else
          orinal_setup = self.use_transactional_fixtures
          self.use_transactional_fixtures = false
          test_case.run
          self.use_transactional_fixtures = orinal_setup
        end
      end

      let(:expires_at) { 1.day.ago.to_i.to_s }

      before do
        stub_request(:post, "https://some_url.com/oauth/token").with(
          body: {
            "client_id" => "123",
            "client_secret" => "456",
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
    end
  end

  describe "#application_token" do
    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

    before do
      stub_request(:post, "https://some_url.com/oauth/token").with(
        body: {
          "client_id" => "123",
          "client_secret" => "456",
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

    it "returns a client credential token setup with application's credentials" do
      expect(account.application_token.token).to eq "the_access_token"
    end
  end

  describe "#oauth_client" do
    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }

    it "returns a BookingSync::Engine.oauth_client setup with application's credentials" do
      expect(account.oauth_client).to be_an OAuth2::Client
      expect(account.oauth_client.id).to eq application.client_id
      expect(account.oauth_client.secret).to eq application.client_secret
    end
  end

  describe "#application" do
    let!(:account) { MultiApplicationsAccount.create!(synced_id: 123, host: "test.example") }
    let!(:application) { Application.create!(host: "test.example", client_id: "123", client_secret: "456") }
    let!(:application2) { Application.create!(host: "test2.example", client_id: "234", client_secret: "567") }

    it "returns the application matching the host" do
      expect(account.application).to eq application
    end
  end

  describe "#api" do
    let!(:application) do
      Application.create!(client_id: "client_id", client_secret: "client_secret", host: "host")
    end
    let!(:account) do
      MultiApplicationsAccount.new(oauth_access_token: "access_token", host: "host")
    end

    it "returns API client initialized with OAuth token" do
      expect(account.api).to be_kind_of(BookingSync::API::Client)
      expect(account.api.token).to eq("access_token")
    end
  end

  describe "#clear_token!" do
    it "clears token related fields on account" do
      account = MultiApplicationsAccount.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires", host: "example.test")

      expect { account.clear_token! }
        .to change { account.reload.oauth_access_token }.from("token").to(nil)
        .and change { account.oauth_refresh_token }.from("refresh").to(nil)
        .and change { account.oauth_expires_at }.from("expires").to(nil)
    end
  end

  describe "#update_token" do
    it "updates the token related fields on account" do
      token = double(token: "new_access_token", refresh_token: "new_refresh_token", expires_at: "new_expires_at")
      account = MultiApplicationsAccount.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires", host: "example.test")

      expect { account.update_token(token) }
        .to change { account.oauth_access_token }.from("token").to("new_access_token")
        .and change { account.oauth_refresh_token }.from("refresh").to("new_refresh_token")
        .and change { account.oauth_expires_at }.from("expires").to("new_expires_at")
    end
  end
end

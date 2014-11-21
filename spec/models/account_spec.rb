require 'spec_helper'

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
    it { is_expected.to validate_uniqueness_of(:uid) }
  end

  describe ".from_omniauth" do
    before { Account.create!(provider: "bookingsync", uid: 456) }

    let(:auth) { OmniAuth.config.mock_auth[:bookingsync] }

    context "when account exists" do
      let!(:account) { Account.create!(provider: "bookingsync", uid: 123) }

      it "loads the existing account" do
        expect(Account.from_omniauth(auth)).to eql(account)
      end

      describe "the updated account" do
        before do
          Account.from_omniauth(auth)
          account.reload
        end

        it_behaves_like "it takes attributes from auth"
      end
    end

    context "when account doesn't exist" do
      it "creates new account" do
        expect {
          Account.from_omniauth(auth)
        }.to change { Account.count }.by(1)
      end

      describe "the newly created account" do
        let!(:account) { Account.from_omniauth(auth) }

        it "sets uid and provider from auth" do
          expect(account.uid).to eq 123
          expect(account.provider).to eq "bookingsync"
        end

        it_behaves_like "it takes attributes from auth"
      end
    end
  end

  describe "#clear_token!" do
    it "clears token related fields on account" do
      account = Account.create!(oauth_access_token: "token",
        oauth_refresh_token: "refresh", oauth_expires_at: "expires")

      account.clear_token!
      account.reload

      expect(account.oauth_access_token).to be_nil
      expect(account.oauth_refresh_token).to be_nil
      expect(account.oauth_expires_at).to be_nil
    end
  end

  describe "#api" do
    it "returns API client initialized with OAuth token" do
      token = double(token: "access_token", expired?: false)
      allow(OAuth2::AccessToken).to receive(:new)
        .and_return(token)
      account = Account.new

      expect(account.api).to be_kind_of(BookingSync::API::Client)
      expect(account.api.token).to eq("access_token")
    end
  end
end

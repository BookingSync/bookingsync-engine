require "spec_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#current_account" do
    context "without an account_id in session" do
      before { session[:account_id] = nil }

      it "returns nil" do
        expect(helper.current_account).to be_nil
      end
    end

    context "with an account_id in session" do
      before { session[:account_id] = 123 }

      context "when using single application setup" do
        before do
          allow(BookingSync::Engine).to receive(:support_multi_applications?).and_return(false)
        end
  
        let!(:account) { Account.create!(synced_id: 123) }

        it "finds and return the current account by synced_id" do
          expect(Account).to receive(:find_by).with(synced_id: 123).and_call_original
          expect(helper.current_account).to eq account
        end
      end

      context "when using multi application setup" do
        before do
          allow(BookingSync::Engine).to receive(:support_multi_applications?).and_return(true)
        end

        let!(:account_1) { MultiApplicationsAccount.create!(host: "example.host", synced_id: 123) }
        let!(:account_2) { MultiApplicationsAccount.create!(host: "test.host", synced_id: 123) }
  
        it "finds and return the current account by host and synced_id" do
          expect(Account).to receive(:find_by).with(host: "test.host", synced_id: 123)
            .and_return(account_2)
          expect(helper.current_account).to eq account_2
        end
      end
    end
  end
end

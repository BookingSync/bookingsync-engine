require "spec_helper"

RSpec.describe AuthenticatedController, type: :controller do
  describe "GET index" do
    context "when engine is embedded" do
      before { BookingSync::Engine.embedded! }

      it "renders autosubmitted form" do
        get :index
        expect(response.status).to eq(200)
        expect(response.body).to include("action='/auth/bookingsync' method='post'")
        expect(response.body).to include("<input type='hidden' name='account_id' value=''>")
        expect(response.header["Content-Type"]).to include("text/html")
      end
    end

    context "when engine is standalone" do
      before { BookingSync::Engine.standalone! }

      it "renders autosubmitted form" do
        get :index
        expect(response.status).to eq(200)
        expect(response.body).to include("action='/auth/bookingsync' method='post'")
        expect(response.body).to include("<input type='hidden' name='account_id' value=''>")
      end
    end
  end

  describe "XHR index" do
    context "when engine is embedded" do
      before { BookingSync::Engine.embedded! }

      it "renders autosubmitted form" do
        get :index, xhr: true
        expect(response.status).to eq(401)
        expect(response.body).to include("action='/auth/bookingsync' method='post'")
        expect(response.body).to include("<input type='hidden' name='account_id' value=''>")
      end
    end

    context "when engine is standalone" do
      before { BookingSync::Engine.standalone! }

      it "renders autosubmitted form" do
        get :index, xhr: true
        expect(response.status).to eq(401)
        expect(response.body).to include("action='/auth/bookingsync' method='post'")
        expect(response.body).to include("<input type='hidden' name='account_id' value=''>")
      end
    end
  end
end

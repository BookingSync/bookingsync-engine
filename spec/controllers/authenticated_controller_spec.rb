require "spec_helper"

RSpec.describe AuthenticatedController, type: :controller do
  before do
    Mime::Type.register "application/vnd.api+json", :api_json
  end

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

  describe "API request" do
    it "returns 401 without response body" do
      get :index, format: :json
      expect(response.status).to eq(401)
      expect(response.body).to eq("")
    end

    context "with vnd.api+json content type" do
      it "returns 401 without response body" do
        request.headers["CONTENT_TYPE"] = "application/vnd.api+json"
        request.headers["ACCEPT"] = "application/vnd.api+json"

        get :index
        expect(response.status).to eq(401)
        expect(response.body).to eq("")
      end
    end
  end
end

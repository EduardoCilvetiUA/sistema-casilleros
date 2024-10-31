require 'rails_helper'

RSpec.describe "Controllers", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/controllers/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/controllers/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/controllers/create"
      expect(response).to have_http_status(:success)
    end
  end

end

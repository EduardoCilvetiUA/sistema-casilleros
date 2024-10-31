require 'rails_helper'

RSpec.describe "Metrics", type: :request do
  describe "GET /usage_stats" do
    it "returns http success" do
      get "/metrics/usage_stats"
      expect(response).to have_http_status(:success)
    end
  end

end

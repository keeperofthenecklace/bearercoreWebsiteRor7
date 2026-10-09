require "test_helper"

# bearerCORE's own trade-claim API was unauthenticated (approve could mark a
# claim ready_to_mint for the retired SmartCHEQ "BC-" path). All nine actions
# now return 410 Gone and change nothing.
class TradeClaimsApiRetiredTest < ActionDispatch::IntegrationTest
  ROUTES = [
    [:get,  "/api/v2/trade_claims"],
    [:post, "/api/v2/trade_claims"],
    [:post, "/api/v2/trade_claims/draft"],
    [:get,  "/api/v2/trade_claims/clearance"],
    [:post, "/api/v2/trade_claims/1/approve"],
    [:post, "/api/v2/trade_claims/1/reject"],
    [:post, "/api/v2/trade_claims/1/re_evaluate"],
    [:post, "/api/v2/trade_claims/1/request_clarification"],
    [:post, "/api/v2/trade_claims/1/cancel"]
  ].freeze

  test "every bearerCORE trade-claim API action returns 410 and writes nothing" do
    before = TradeClaim.count
    ROUTES.each do |verb, path|
      send(verb, path, params: { reference: "X", amount: 1 }, as: :json)
      assert_response :gone, "#{verb.upcase} #{path}"
      assert_equal "gone", JSON.parse(response.body)["error"]
    end
    assert_equal before, TradeClaim.count
  end
end

require "test_helper"
require "minitest/mock"

# The institutional portal login asks for the operator's TOTP code and forwards
# it to SmartCHEQ's auth bridge, which refuses any login without a valid code.
class CentralBankLoginTotpTest < ActionDispatch::IntegrationTest
  FakeResponse = Struct.new(:body)

  # Stands in for Net::HTTP: records the request body and answers like the bridge.
  class FakeHttp
    attr_accessor :use_ssl, :open_timeout, :read_timeout
    attr_reader :bodies
    def initialize(answer) = (@answer = answer; @bodies = [])
    def request(req) = (@bodies << JSON.parse(req.body); FakeResponse.new(@answer.to_json))
  end

  def creds(otp)
    { username: "op@example.test", password: "pw-#{SecureRandom.hex(4)}", institution_swift: "ZEIBNGLA", otp_code: otp }.compact
  end

  test "the login page asks for the authenticator code" do
    get central_bank_login_path
    assert_response :success
    assert_select "input#otp_code[name=otp_code][required][autocomplete=one-time-code]"
  end

  test "a login without a code is refused before SmartCHEQ is contacted" do
    fake = FakeHttp.new({ success: true, data: {} })
    Net::HTTP.stub(:new, fake) do
      post central_bank_session_path, params: creds(nil)
    end
    assert_response :unprocessable_entity
    assert_empty fake.bodies
    refute session[:central_bank_authenticated]
  end

  test "the code is forwarded to SmartCHEQ, and a refusal there is not a session" do
    fake = FakeHttp.new({ success: false, error: "Invalid or missing authenticator code." })
    Net::HTTP.stub(:new, fake) do
      post central_bank_session_path, params: creds("123456")
    end
    assert_equal "123456", fake.bodies.first["otp_code"]
    assert_response :unprocessable_entity
    refute session[:central_bank_authenticated]
  end

  test "an accepted code establishes the portal session" do
    fake = FakeHttp.new({ success: true, data: { "operator_username" => "op@example.test",
                                                 "institution_swift" => "ZEIBNGLA", "role" => "compliance_officer" } })
    Net::HTTP.stub(:new, fake) do
      post central_bank_session_path, params: creds("654321")
    end
    assert_equal "654321", fake.bodies.first["otp_code"]
    assert_response :redirect
    assert session[:central_bank_authenticated]
  end
end

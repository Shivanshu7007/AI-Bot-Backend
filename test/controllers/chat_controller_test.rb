require "test_helper"
require "webmock/minitest"

# NOTE: Add `gem "webmock"` to the :test group in Gemfile to enable HTTP stubbing.
# Run with: rails test test/controllers/chat_controller_test.rb

class ChatControllerTest < ActionDispatch::IntegrationTest
  PYTHON_URL = "http://localhost:8000"

  setup do
    ENV["PYTHON_API_URL"]  = PYTHON_URL
    ENV["SERVICE_API_KEY"] = "test-service-key"
    WebMock.enable!
  end

  teardown do
    WebMock.reset!
    WebMock.disable!
  end

  # -----------------------------------------------------------------------
  # Validation
  # -----------------------------------------------------------------------

  test "returns 400 when product_id is missing" do
    post "/chat", params: { question: "How do I use this kit?" },
                  as: :json
    assert_response :bad_request
    assert_equal "Missing parameters.", response.parsed_body["reply"]
  end

  test "returns 400 when question is missing" do
    post "/chat", params: { product_id: 1 }, as: :json
    assert_response :bad_request
  end

  test "returns 400 when question exceeds 1000 characters" do
    post "/chat", params: { product_id: 1, question: "x" * 1001 }, as: :json
    assert_response :bad_request
    assert_match(/too long/i, response.parsed_body["reply"])
  end

  test "returns 404 when product does not exist" do
    post "/chat", params: { product_id: 999_999, question: "Hello?" }, as: :json
    assert_response :not_found
    assert_equal "Product not found.", response.parsed_body["reply"]
  end

  # -----------------------------------------------------------------------
  # Happy path (requires a Product fixture)
  # -----------------------------------------------------------------------

  test "returns bot reply when Python service responds 200" do
    product = products(:one)

    stub_request(:post, "#{PYTHON_URL}/ask")
      .to_return(status: 200, body: "According to the product manual, store at 4°C.")

    post "/chat", params: { product_id: product.id, question: "Storage instructions?" },
                  as: :json

    assert_response :success
    assert_match(/According to the product manual/, response.parsed_body["reply"])
  end

  test "forwards history to Python service" do
    product = products(:one)
    history = [{ sender: "user", text: "Previous question" }]

    stub_request(:post, "#{PYTHON_URL}/ask")
      .with { |req| JSON.parse(req.body)["history"].present? }
      .to_return(status: 200, body: "Answer using history context.")

    post "/chat",
         params: { product_id: product.id, question: "Follow-up?", history: history },
         as: :json

    assert_response :success
  end

  test "returns no_knowledge_base status when Python returns that JSON" do
    product = products(:one)

    stub_request(:post, "#{PYTHON_URL}/ask")
      .to_return(status: 200, body: '{"status":"no_knowledge_base"}',
                 headers: { "Content-Type" => "application/json" })

    post "/chat", params: { product_id: product.id, question: "Anything?" }, as: :json

    assert_response :success
    assert_equal "no_knowledge_base", response.parsed_body["status"]
  end

  test "returns error reply when Python service returns non-200" do
    product = products(:one)

    stub_request(:post, "#{PYTHON_URL}/ask").to_return(status: 500, body: "Internal error")

    post "/chat", params: { product_id: product.id, question: "Storage?" }, as: :json

    assert_response :success  # Rails itself returns 200 with an error message in the body
    assert_match(/try again/i, response.parsed_body["reply"])
  end

  test "returns timeout message when Python service times out" do
    product = products(:one)

    stub_request(:post, "#{PYTHON_URL}/ask").to_timeout

    post "/chat", params: { product_id: product.id, question: "Storage?" }, as: :json

    assert_response :success
    assert_match(/timed out/i, response.parsed_body["reply"])
  end
end

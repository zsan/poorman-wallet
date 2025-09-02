require "test_helper"

class Api::V1::TransactionsControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:one)
    @wallet = @user.wallet_for("USD")
    @wallet.update!(balance: 1000.0)
    @headers = { "Authorization" => "Bearer demo-api-key", "Content-Type" => "application/json" }
  end

  test "should get index with valid auth" do
    get api_v1_transactions_url, headers: @headers
    assert_response :success

    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert json_response["data"].is_a?(Array)
  end

  test "should not get index without auth" do
    get api_v1_transactions_url
    assert_response :unauthorized

    json_response = JSON.parse(response.body)
    assert_equal "Unauthorized", json_response["error"]
  end

  test "should create credit transaction" do
    assert_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "credit",
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 100.0,
             currency: "USD",
             description: "Test credit"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Credit transaction created successfully", json_response["message"]
    assert_equal "100.0", json_response["data"]["amount"]
    assert_equal "credit", json_response["data"]["transaction_type"]
  end

  test "should create debit transaction with sufficient balance" do
    # Ensure wallet has sufficient balance
    @wallet.update!(balance: 1000.0)

    assert_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "debit",
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 50.0,
             currency: "USD",
             description: "Test debit"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Debit transaction created successfully", json_response["message"]
    assert_equal "50.0", json_response["data"]["amount"]
    assert_equal "debit", json_response["data"]["transaction_type"]
  end

  test "should not create debit transaction with insufficient balance" do
    # Set wallet balance to low amount
    @wallet.update!(balance: 10.0)

    assert_no_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "debit",
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 100.0,
             currency: "USD",
             description: "Test debit"
           }.to_json,
           headers: @headers
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
    assert_equal "Insufficient balance", json_response["message"]
  end

  test "should create transfer transaction between users" do
    # Use second user from fixture
    @user2 = users(:two)
    @wallet2 = @user2.wallet_for("USD")

    # Ensure source wallet has sufficient balance
    @wallet.update!(balance: 1000.0)

    assert_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "transfer",
             source_wallet_id: @user.id,
             source_wallet_type: "user",
             target_wallet_id: @user2.id,
             target_wallet_type: "user",
             amount: 200.0,
             currency: "USD",
             description: "Test transfer"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Transfer transaction created successfully", json_response["message"]
    assert_equal "200.0", json_response["data"]["amount"]
    assert_equal "transfer", json_response["data"]["transaction_type"]
    assert_not_nil json_response["data"]["source_wallet"]
    assert_not_nil json_response["data"]["target_wallet"]
  end

  test "should not create transfer with insufficient balance" do
    # Use second user from fixture
    @user2 = users(:two)
    @user2.wallet_for("USD")

    # Set source wallet balance to low amount
    @wallet.update!(balance: 50.0)

    assert_no_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "transfer",
             source_wallet_id: @user.id,
             source_wallet_type: "user",
             target_wallet_id: @user2.id,
             target_wallet_type: "user",
             amount: 100.0,
             currency: "USD",
             description: "Test transfer"
           }.to_json,
           headers: @headers
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
    assert_equal "Insufficient balance", json_response["message"]
  end

  test "should not create transaction with invalid type" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "invalid",
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 100.0,
             currency: "USD"
           }.to_json,
           headers: @headers
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
    assert_equal "Invalid transaction type. Must be credit, debit, or transfer", json_response["message"]
  end

  test "should not create transaction with zero amount" do
    assert_no_difference("Transaction.count") do
      post api_v1_transactions_url,
           params: {
             transaction_type: "credit",
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 0,
             currency: "USD"
           }.to_json,
           headers: @headers
    end

    assert_response :bad_request
    json_response = JSON.parse(response.body)
    assert_equal "error", json_response["status"]
    assert_equal "Amount must be greater than 0", json_response["message"]
  end

  test "should use credit endpoint directly" do
    assert_difference("Transaction.count") do
      post credit_api_v1_transactions_url,
           params: {
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 75.0,
             currency: "USD",
             description: "Direct credit test"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Credit transaction created successfully", json_response["message"]
  end

  test "should use debit endpoint directly" do
    @wallet.update!(balance: 1000.0)

    assert_difference("Transaction.count") do
      post debit_api_v1_transactions_url,
           params: {
             wallet_id: @user.id,
             wallet_type: "user",
             amount: 25.0,
             currency: "USD",
             description: "Direct debit test"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Debit transaction created successfully", json_response["message"]
  end

  test "should use transfer endpoint directly" do
    @user2 = users(:two)
    @user2.wallet_for("USD")
    @wallet.update!(balance: 1000.0)

    assert_difference("Transaction.count") do
      post transfer_api_v1_transactions_url,
           params: {
             source_wallet_id: @user.id,
             source_wallet_type: "user",
             target_wallet_id: @user2.id,
             target_wallet_type: "user",
             amount: 150.0,
             currency: "USD",
             description: "Direct transfer test"
           }.to_json,
           headers: @headers
    end

    assert_response :success
    json_response = JSON.parse(response.body)
    assert_equal "success", json_response["status"]
    assert_equal "Transfer transaction created successfully", json_response["message"]
  end
end

require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(username: "testuser", email: "test@example.com", password: "password123")
    @user_wallet = @user.wallet_for("USD")
    @team = Team.create!(name: "Test Team", description: "Test team description")
    @team_wallet = @team.wallet_for("USD")
  end

  test "should create credit transaction" do
    assert_difference "Transaction.count" do
      transaction = Transaction.create_credit!(@user_wallet, 100.0, "USD", "Test credit")
      assert_equal "credit", transaction.transaction_type
      assert_equal 100.0, transaction.amount
      assert_nil transaction.source_wallet
      assert_equal @user_wallet, transaction.target_wallet
    end
  end

  test "should create debit transaction with sufficient balance" do
    # First add some money
    Transaction.create_credit!(@user_wallet, 200.0, "USD", "Initial deposit")
    @user_wallet.sync_balance!

    assert_difference "Transaction.count" do
      transaction = Transaction.create_debit!(@user_wallet, 50.0, "USD", "Test debit")
      assert_equal "debit", transaction.transaction_type
      assert_equal 50.0, transaction.amount
      assert_equal @user_wallet, transaction.source_wallet
      assert_nil transaction.target_wallet
    end
  end

  test "should not create debit transaction with insufficient balance" do
    assert_raises(ActiveRecord::RecordInvalid) do
      Transaction.create_debit!(@user_wallet, 100.0, "USD", "Test debit")
    end
  end

  test "should create transfer transaction" do
    # Add money to source wallet
    Transaction.create_credit!(@user_wallet, 200.0, "USD", "Initial deposit")
    @user_wallet.sync_balance!

    assert_difference "Transaction.count" do
      transaction = Transaction.create_transfer!(@user_wallet, @team_wallet, 75.0, "USD", "Test transfer")
      assert_equal "transfer", transaction.transaction_type
      assert_equal 75.0, transaction.amount
      assert_equal @user_wallet, transaction.source_wallet
      assert_equal @team_wallet, transaction.target_wallet
    end
  end

  test "should validate transaction type rules" do
    # Credit should have target_wallet but no source_wallet
    transaction = Transaction.new(
      amount: 100.0,
      currency: "USD",
      transaction_type: "credit",
      source_wallet: @user_wallet,
      target_wallet: @user_wallet
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:source_wallet], "must be nil for credit transactions"

    # Debit should have source_wallet but no target_wallet
    transaction = Transaction.new(
      amount: 100.0,
      currency: "USD",
      transaction_type: "debit",
      source_wallet: @user_wallet,
      target_wallet: @user_wallet
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:target_wallet], "must be nil for debit transactions"
  end

  test "should validate currency consistency" do
    idr_wallet = @user.wallet_for("IDR")

    transaction = Transaction.new(
      amount: 100.0,
      currency: "USD",
      transaction_type: "credit",
      target_wallet: idr_wallet
    )
    assert_not transaction.valid?
    assert_includes transaction.errors[:currency], "must match target wallet currency"
  end
end

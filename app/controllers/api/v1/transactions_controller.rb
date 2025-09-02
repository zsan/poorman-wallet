class Api::V1::TransactionsController < Api::V1::BaseController
  before_action :set_transaction, only: [ :show ]

  def index
    transactions = Transaction.includes(:source_wallet, :target_wallet)
                             .order(created_at: :desc)
                             .limit(params[:limit] || 50)

    success_response(transactions.map { |t| transaction_json(t) })
  end

  def show
    success_response(transaction_json(@transaction))
  end

  def create
    transaction_type = params[:transaction_type]

    case transaction_type
    when "credit"
      create_credit
    when "debit"
      create_debit
    when "transfer"
      create_transfer
    else
      error_response("Invalid transaction type. Must be credit, debit, or transfer")
    end
  end

  def credit
    create_credit
  end

  def debit
    create_debit
  end

  def transfer
    create_transfer
  end

  private

  def set_transaction
    @transaction = Transaction.find(params[:id])
  end

  def create_credit
    wallet = find_wallet(params[:wallet_id], params[:wallet_type])
    amount = params[:amount].to_f
    currency = params[:currency] || "USD"
    description = params[:description]

    return error_response("Wallet not found") unless wallet
    return error_response("Amount must be greater than 0") unless amount > 0

    # ACID transaction
    transaction = nil
    ActiveRecord::Base.transaction do
      transaction = Transaction.create_credit!(wallet, amount, currency, description)
      wallet.update!(balance: wallet.balance + amount)
    end

    success_response(
      transaction_json(transaction),
      "Credit transaction created successfully"
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response("Transaction failed: #{e.record.errors.full_messages.join(', ')}")
  end

  def create_debit
    wallet = find_wallet(params[:wallet_id], params[:wallet_type])
    amount = params[:amount].to_f
    currency = params[:currency] || "USD"
    description = params[:description]

    return error_response("Wallet not found") unless wallet
    return error_response("Amount must be greater than 0") unless amount > 0
    return error_response("Insufficient balance") unless wallet.sufficient_balance?(amount)

    # ACID transaction
    transaction = nil
    ActiveRecord::Base.transaction do
      transaction = Transaction.create_debit!(wallet, amount, currency, description)
      wallet.update!(balance: wallet.balance - amount)
    end

    success_response(
      transaction_json(transaction),
      "Debit transaction created successfully"
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response("Transaction failed: #{e.record.errors.full_messages.join(', ')}")
  end

  def create_transfer
    source_wallet = find_wallet(params[:source_wallet_id], params[:source_wallet_type])
    target_wallet = find_wallet(params[:target_wallet_id], params[:target_wallet_type])
    amount = params[:amount].to_f
    currency = params[:currency] || "USD"
    description = params[:description]

    return error_response("Source wallet not found") unless source_wallet
    return error_response("Target wallet not found") unless target_wallet
    return error_response("Amount must be greater than 0") unless amount > 0
    return error_response("Insufficient balance") unless source_wallet.sufficient_balance?(amount)
    return error_response("Currency mismatch") unless source_wallet.currency == target_wallet.currency

    # ACID transaction
    transaction = nil
    ActiveRecord::Base.transaction do
      transaction = Transaction.create_transfer!(source_wallet, target_wallet, amount, currency, description)
      source_wallet.update!(balance: source_wallet.balance - amount)
      target_wallet.update!(balance: target_wallet.balance + amount)
    end

    success_response(
      transaction_json(transaction),
      "Transfer transaction created successfully"
    )
  rescue ActiveRecord::RecordInvalid => e
    error_response("Transaction failed: #{e.record.errors.full_messages.join(', ')}")
  end

  def find_wallet(wallet_id, wallet_type)
    return nil unless wallet_id && wallet_type

    case wallet_type.downcase
    when "user"
      User.find(wallet_id).wallet_for(params[:currency] || "USD")
    when "team"
      Team.find(wallet_id).wallet_for(params[:currency] || "USD")
    when "stock"
      Stock.find(wallet_id).wallet_for(params[:currency] || "USD")
    when "wallet"
      Wallet.find(wallet_id)
    else
      nil
    end
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def transaction_json(transaction)
    {
      id: transaction.id,
      amount: transaction.amount,
      currency: transaction.currency,
      transaction_type: transaction.transaction_type,
      description: transaction.description,
      source_wallet: transaction.source_wallet ? wallet_summary(transaction.source_wallet) : nil,
      target_wallet: transaction.target_wallet ? wallet_summary(transaction.target_wallet) : nil,
      created_at: transaction.created_at,
      updated_at: transaction.updated_at
    }
  end

  def wallet_summary(wallet)
    {
      id: wallet.id,
      currency: wallet.currency,
      balance: wallet.calculated_balance,
      owner_type: wallet.walletable_type,
      owner_id: wallet.walletable_id
    }
  end
end

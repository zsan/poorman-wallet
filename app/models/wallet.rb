class Wallet < ApplicationRecord
  belongs_to :walletable, polymorphic: true

  has_many :source_transactions, class_name: "Transaction", foreign_key: "source_wallet_id", dependent: :restrict_with_error
  has_many :target_transactions, class_name: "Transaction", foreign_key: "target_wallet_id", dependent: :restrict_with_error

  validates :balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, inclusion: { in: %w[USD EUR IDR JPY GBP] }
  validates :walletable_type, :walletable_id, presence: true

  # Calculate balance from transactions instead of stored balance
  def calculated_balance
    credits = target_transactions.sum(:amount) || 0
    debits = source_transactions.sum(:amount) || 0
    credits - debits
  end

  # Get all transactions for this wallet
  def all_transactions
    Transaction.where("source_wallet_id = ? OR target_wallet_id = ?", id, id)
               .order(created_at: :desc)
  end

  # Check if wallet has sufficient balance for withdrawal
  def sufficient_balance?(amount)
    balance >= amount
  end

  # Update the stored balance to match calculated balance
  def sync_balance!
    update!(balance: calculated_balance)
  end
end

class Transaction < ApplicationRecord
  belongs_to :source_wallet, class_name: 'Wallet', optional: true
  belongs_to :target_wallet, class_name: 'Wallet', optional: true

  TRANSACTION_TYPES = %w[credit debit transfer].freeze
  CURRENCIES = %w[USD EUR IDR JPY GBP].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, inclusion: { in: CURRENCIES }
  validates :transaction_type, presence: true, inclusion: { in: TRANSACTION_TYPES }

  # Custom validations based on transaction type
  validate :validate_transaction_type_rules
  validate :validate_currency_consistency
  validate :validate_sufficient_balance, on: :create

  # Scopes
  scope :credits, -> { where(transaction_type: 'credit') }
  scope :debits, -> { where(transaction_type: 'debit') }
  scope :transfers, -> { where(transaction_type: 'transfer') }
  scope :for_wallet, ->(wallet_id) { where("source_wallet_id = ? OR target_wallet_id = ?", wallet_id, wallet_id) }

  # Class methods for creating transactions
  def self.create_credit!(wallet, amount, currency, description = nil)
    create!(
      target_wallet: wallet,
      source_wallet: nil,
      amount: amount,
      currency: currency,
      transaction_type: 'credit',
      description: description || "Credit to #{wallet.walletable_type} wallet"
    )
  end

  def self.create_debit!(wallet, amount, currency, description = nil)
    create!(
      source_wallet: wallet,
      target_wallet: nil,
      amount: amount,
      currency: currency,
      transaction_type: 'debit',
      description: description || "Debit from #{wallet.walletable_type} wallet"
    )
  end

  def self.create_transfer!(from_wallet, to_wallet, amount, currency, description = nil)
    create!(
      source_wallet: from_wallet,
      target_wallet: to_wallet,
      amount: amount,
      currency: currency,
      transaction_type: 'transfer',
      description: description || "Transfer from #{from_wallet.walletable_type} to #{to_wallet.walletable_type}"
    )
  end

  private

  def validate_transaction_type_rules
    case transaction_type
    when 'credit'
      errors.add(:source_wallet, 'must be nil for credit transactions') if source_wallet.present?
      errors.add(:target_wallet, 'must be present for credit transactions') if target_wallet.blank?
    when 'debit'
      errors.add(:target_wallet, 'must be nil for debit transactions') if target_wallet.present?
      errors.add(:source_wallet, 'must be present for debit transactions') if source_wallet.blank?
    when 'transfer'
      errors.add(:source_wallet, 'must be present for transfer transactions') if source_wallet.blank?
      errors.add(:target_wallet, 'must be present for transfer transactions') if target_wallet.blank?
      errors.add(:base, 'source and target wallets cannot be the same') if source_wallet == target_wallet
    end
  end

  def validate_currency_consistency
    if source_wallet&.currency != currency && source_wallet.present?
      errors.add(:currency, 'must match source wallet currency')
    end

    if target_wallet&.currency != currency && target_wallet.present?
      errors.add(:currency, 'must match target wallet currency')
    end
  end

  def validate_sufficient_balance
    return unless source_wallet && amount

    unless source_wallet.sufficient_balance?(amount)
      errors.add(:amount, 'insufficient balance in source wallet')
    end
  end
end

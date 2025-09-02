class User < ApplicationRecord
  has_secure_password

  has_many :wallets, as: :walletable, dependent: :destroy

  validates :username, presence: true, uniqueness: true, length: { minimum: 3, maximum: 50 }
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  # Create default wallets for supported currencies
  after_create :create_default_wallets

  # Get wallet for specific currency
  def wallet_for(currency = "USD")
    wallets.find_by(currency: currency) || create_wallet_for(currency)
  end

  # Get all wallet balances
  def wallet_balances
    wallets.includes(:source_transactions, :target_transactions).map do |wallet|
      {
        currency: wallet.currency,
        balance: wallet.calculated_balance
      }
    end
  end

  # Total balance in USD (simplified conversion)
  def total_balance_usd
    wallets.sum { |wallet| wallet.calculated_balance * currency_to_usd_rate(wallet.currency) }
  end

  private

  def create_default_wallets
    %w[USD IDR].each do |currency|
      create_wallet_for(currency)
    end
  end

  def create_wallet_for(currency)
    wallets.create!(currency: currency, balance: 0.0)
  end

  # Simplified currency conversion rates
  def currency_to_usd_rate(currency)
    case currency
    when "USD" then 1.0
    when "EUR" then 1.1
    when "IDR" then 0.000067
    when "JPY" then 0.0067
    when "GBP" then 1.25
    else 1.0
    end
  end
end

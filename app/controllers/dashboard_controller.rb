class DashboardController < ApplicationController
  def index
    @user_wallets = current_user.wallet_balances
    @recent_transactions = Transaction.includes(:source_wallet, :target_wallet)
                                    .where("source_wallet_id IN (?) OR target_wallet_id IN (?)",
                                           current_user.wallets.pluck(:id),
                                           current_user.wallets.pluck(:id))
                                    .order(created_at: :desc)
                                    .limit(10)

    # Get stock prices using our library - using Indian stocks that are actually available in the API
    rapid_api = Rails.application.credentials.rapidapi_key
    begin
      @stock_prices = LatestStockPrice::Prices.get([ "NIFTY 50", "BAJFINANCE" ], rapid_api)
    rescue => e
      @stock_prices = []
      Rails.logger.error "Failed to fetch stock prices: #{e.message}"
    end

    @total_balance_usd = current_user.total_balance_usd
  end
end

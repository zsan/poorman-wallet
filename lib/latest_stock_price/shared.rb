module LatestStockPrice
  module Shared
    private

    def format_price_data(data)
      {
        symbol: data["symbol"] || data[:symbol],
        price: (data["price"] || data[:price])&.to_f,
        change: (data["change"] || data[:change])&.to_f,
        change_percent: (data["pChange"] || data[:change_percent])&.to_f,
        last_updated: data["lastUpdateTime"] || data[:last_updated],
        currency: data["currency"] || data[:currency] || "USD",
        market: data["market"] || data[:market]
      }
    end

    def mock_price_data(symbol)
      base_prices = {
        "AAPL" => 150.00,
        "GOOGL" => 2500.00,
        "MSFT" => 300.00,
        "TSLA" => 800.00,
        "AMZN" => 3200.00,
        "META" => 280.00,
        "NVDA" => 450.00,
        "NFLX" => 380.00,
        "BBRI.JK" => 4500.00,
        "BBCA.JK" => 8200.00,
        "TLKM.JK" => 3800.00,
        "BMRI.JK" => 5200.00,
        "ASII.JK" => 6800.00,
        "UNVR.JK" => 4200.00,
        "ICBP.JK" => 8900.00,
        "KLBF.JK" => 1500.00,
        "INDF.JK" => 7200.00,
        "GGRM.JK" => 65000.00
      }

      base_price = base_prices[symbol.upcase] || (100.00 + rand(1000.0))
      variation = (rand(-5.0..5.0) / 100.0) * base_price
      current_price = base_price + variation

      {
        symbol: symbol.upcase,
        price: current_price.round(2),
        change: variation.round(2),
        change_percent: ((variation / base_price) * 100).round(2),
        last_updated: Time.current.iso8601,
        currency: symbol.upcase.include?(".JK") ? "IDR" : "USD",
        market: symbol.upcase.include?(".JK") ? "IDX" : "NASDAQ"
      }
    end

    def get_all_prices
      # Use PriceAll as the single source of truth
      PriceAll.new(@api_key).get
    end
  end
end

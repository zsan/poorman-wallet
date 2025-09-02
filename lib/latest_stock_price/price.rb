module LatestStockPrice
  class Price < Client
    include Shared

    # Get price for a single stock symbol
    def self.get(symbol, api_key = nil)
      new(api_key).get(symbol)
    end

    def get(symbol)
      raise ArgumentError, "Symbol is required" if symbol.nil? || symbol.empty?

      # Get all prices and find the specific symbol
      all_prices = get_all_prices
      stock_data = all_prices.find { |price_data| price_data[:symbol]&.upcase == symbol.upcase }

      if stock_data
        stock_data
      elsif !(@api_key.nil? || @api_key.empty? || @api_key == "demo-api-key")
        # If no match found from API and we have a real API key,
        # fallback to mock data for the requested symbol
        mock_price_data(symbol)
      else
        raise APIError, "No data found for symbol: #{symbol}"
      end
    end
  end
end

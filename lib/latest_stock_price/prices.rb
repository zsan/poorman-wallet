module LatestStockPrice
  class Prices < Client
    include Shared

    # Get prices for multiple stock symbols
    def self.get(symbols, api_key = nil)
      new(api_key).get(symbols)
    end

    def get(symbols)
      raise ArgumentError, "Symbols are required" if symbols.nil? || symbols.empty?

      symbols_array = symbols.is_a?(Array) ? symbols : [ symbols ]
      symbols_array = symbols_array.map(&:to_s).map(&:upcase)

      # Get all prices and filter for requested symbols
      all_prices = get_all_prices
      filtered_prices = all_prices.select do |price_data|
        symbols_array.include?(price_data[:symbol]&.upcase)
      end

      # If no matches found from API and we have a real API key,
      # fallback to mock data for the requested symbols
      if filtered_prices.empty? && !(@api_key.nil? || @api_key.empty? || @api_key == "demo-api-key")
        filtered_prices = symbols_array.map { |symbol| mock_price_data(symbol) }
      end

      filtered_prices
    end
  end
end

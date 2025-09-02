module LatestStockPrice
  class PriceAll < Client
    include Shared

    # Get all available stock prices
    def self.get(api_key = nil)
      new(api_key).get
    end

    def get
      # For demo purposes, return mock data if no API key is configured
      if @api_key.nil? || @api_key.empty? || @api_key == "demo-api-key"
        return mock_all_prices_data
      end

      response = make_request("any")

      if response.is_a?(Array)
        response.map { |data| format_price_data(data) }
      else
        raise APIError, "Failed to fetch all stock prices"
      end
    end

    private

    def mock_all_prices_data
      # Mock data for demonstration - popular stocks
      symbols = [
        "AAPL", "GOOGL", "MSFT", "TSLA", "AMZN", "META", "NVDA", "NFLX",
        "BBRI.JK", "BBCA.JK", "TLKM.JK", "BMRI.JK", "ASII.JK", "UNVR.JK",
        "ICBP.JK", "KLBF.JK", "INDF.JK", "GGRM.JK"
      ]

      symbols.map { |symbol| mock_price_data(symbol) }
    end
  end
end

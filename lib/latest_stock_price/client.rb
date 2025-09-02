module LatestStockPrice
  class Client
    def initialize(api_key = nil)
      @api_key = api_key || LatestStockPrice.api_key
      raise ConfigurationError, "API key is required" unless @api_key
    end

    private

    def make_request(endpoint, params = {})
      uri = URI("#{LatestStockPrice.base_url}/#{endpoint}")
      uri.query = URI.encode_www_form(params) unless params.empty?

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Get.new(uri)
      request["X-RapidAPI-Key"] = @api_key
      request["X-RapidAPI-Host"] = "latest-stock-price.p.rapidapi.com"

      response = http.request(request)

      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 401
        raise APIError, "Unauthorized - check your API key"
      when 403
        raise APIError, "Forbidden - API key may be invalid or expired"
      when 429
        raise APIError, "Rate limit exceeded"
      when 500..599
        raise APIError, "Server error - please try again later"
      else
        raise APIError, "HTTP #{response.code}: #{response.message}"
      end
    rescue JSON::ParserError
      raise APIError, "Invalid JSON response from API"
    rescue Net::OpenTimeout, Net::ReadTimeout, Timeout::Error
      raise APIError, "Request timeout - please try again"
    rescue StandardError => e
      raise APIError, "Network error: #{e.message}"
    end
  end
end

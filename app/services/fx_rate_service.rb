require 'net/http'
require 'uri'

# Fetches live FX rates from open.er-api.com (free, no API key).
# All rates are USD-based: rates[X] = units of X per 1 USD.
# Cross-rate: 1 FROM = (rates[TO] / rates[FROM]) TO.
# Results are cached in Rails.cache for 1 hour to avoid repeated requests.
class FxRateService
  BASE_URL  = "https://open.er-api.com/v6/latest/USD".freeze
  CACHE_KEY = "fx_rates_usd_base".freeze
  CACHE_TTL = 1.hour

  # Returns a Float or nil if either currency is unknown / fetch failed.
  def self.rate(from_currency, to_currency)
    from = from_currency.to_s.upcase
    to   = to_currency.to_s.upcase
    return 1.0 if from == to

    rates = fetch_rates
    return nil unless rates

    from_rate = rates[from]
    to_rate   = rates[to]
    return nil unless from_rate && to_rate && from_rate.nonzero?

    (to_rate.to_f / from_rate.to_f).round(from_rate > 100 ? 2 : from_rate > 1 ? 4 : 6)
  end

  def self.fetch_rates
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      uri      = URI(BASE_URL)
      response = Net::HTTP.get_response(uri)
      raise "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      raise "API error: #{data['error-type']}" if data["result"] != "success"

      data["rates"]
    end
  rescue => e
    Rails.logger.error "[FxRateService] fetch failed: #{e.class} #{e.message}"
    nil
  end
end

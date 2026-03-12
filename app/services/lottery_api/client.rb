require "net/http"
require "json"

module LotteryApi
  class Client
    TIMEOUT = 10

    def lotteries
      get("/open_api/v1/lotteries")
    end

    def lottery_schedules
      get("/open_api/v1/lottery_schedules")
    end

    def draws(date:, loteria_id:)
      formatted_date = date.is_a?(Date) ? date.strftime("%d/%m/%Y") : date
      get("/open_api/v1/draws", date: formatted_date, loteria_id: loteria_id)
    end

    private

    def get(path, params = {})
      uri = build_uri(path, params)

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = TIMEOUT
      http.read_timeout = TIMEOUT

      request = Net::HTTP::Get.new(uri)
      request["APIKEY"] = LotteryApi.api_key
      request["Accept"] = "application/json"

      response = http.request(request)

      handle_response(response)
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      raise LotteryApi::Error, "Request timed out: #{e.message}"
    rescue Errno::ECONNREFUSED, SocketError => e
      raise LotteryApi::Error, "Connection error: #{e.message}"
    end

    def build_uri(path, params = {})
      uri = URI.parse("#{LotteryApi.base_url}#{path}")
      uri.query = URI.encode_www_form(params) if params.any?
      uri
    end

    def handle_response(response)
      case response.code.to_i
      when 200..299
        JSON.parse(response.body)
      when 401
        raise LotteryApi::Error, "Unauthorized: invalid API key"
      when 404
        raise LotteryApi::Error, "Not found: #{response.code}"
      when 400..499
        raise LotteryApi::Error, "Client error: #{response.code} #{response.body}"
      when 500..599
        raise LotteryApi::Error, "Server error: #{response.code} #{response.body}"
      else
        raise LotteryApi::Error, "Unexpected response: #{response.code}"
      end
    end
  end
end

module LotteryApi
  class Error < StandardError; end

  def self.base_url
    ENV.fetch("LOTTERY_API_BASE_URL", "https://api.sispts.com")
  end

  def self.api_key
    ENV.fetch("LOTTERY_API_KEY")
  end
end

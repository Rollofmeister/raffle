module LotteryApi
  class FetchDrawsService
    def initialize(lottery:, date:, client: LotteryApi::Client.new)
      @lottery = lottery
      @date = date.is_a?(String) ? Date.parse(date) : date
      @client = client
    end

    def call
      data = @client.draws(date: @date, loteria_id: @lottery.external_id)
      draws = []

      Array(data).each do |result|
        draw_time = result["horario"]
        schedule = @lottery.lottery_schedules.find_by(draw_time: draw_time)
        next unless schedule

        draw = Draw.find_or_initialize_by(
          lottery_schedule: schedule,
          draw_date: @date
        )

        draw.prizes = parse_prizes(result["posicoes"] || result["prizes"] || [])
        draw.status = :processed
        draw.save!

        draws << draw
      end

      draws
    end

    private

    def parse_prizes(posicoes)
      Array(posicoes).map do |p|
        {
          "position"    => p["posicao"] || p["position"],
          "value"       => p["valor"] || p["value"],
          "group_value" => p["grupo_valor"] || p["group_value"],
          "group_name"  => p["grupo_nome"] || p["group_name"]
        }
      end
    end
  end
end

require "rails_helper"

RSpec.describe LotteryApi::Client do
  let(:client) { described_class.new }
  let(:base_url) { "https://api.sispts.com" }
  let(:api_key) { "test-api-key" }

  before do
    allow(LotteryApi).to receive(:base_url).and_return(base_url)
    allow(LotteryApi).to receive(:api_key).and_return(api_key)
  end

  describe "#lotteries" do
    let(:response_body) do
      [
        { "loteria_id" => 1, "nome" => "Loteria Federal", "abreviacao" => "LF" },
        { "loteria_id" => 3, "nome" => "PT-RIO", "abreviacao" => "PTR" }
      ].to_json
    end

    before do
      stub_request(:get, "#{base_url}/open_api/v1/lotteries")
        .with(headers: { "APIKEY" => api_key })
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "returns parsed lottery data" do
      result = client.lotteries
      expect(result).to be_an(Array)
      expect(result.first["loteria_id"]).to eq(1)
      expect(result.first["nome"]).to eq("Loteria Federal")
    end
  end

  describe "#lottery_schedules" do
    let(:response_body) do
      [
        { "loteria_id" => 3, "nome" => "PT-RIO", "sorteio" => "14:20" },
        { "loteria_id" => 3, "nome" => "PT-RIO", "sorteio" => "16:20" }
      ].to_json
    end

    before do
      stub_request(:get, "#{base_url}/open_api/v1/lottery_schedules")
        .with(headers: { "APIKEY" => api_key })
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "returns parsed schedule data" do
      result = client.lottery_schedules
      expect(result).to be_an(Array)
      expect(result.first["sorteio"]).to eq("14:20")
    end
  end

  describe "#draws" do
    let(:date) { Date.new(2026, 3, 12) }
    let(:response_body) do
      [
        {
          "horario" => "14:20",
          "posicoes" => [
            { "posicao" => 1, "valor" => "1234", "grupo_valor" => "12", "grupo_nome" => "Elefante" }
          ]
        }
      ].to_json
    end

    before do
      stub_request(:get, "#{base_url}/open_api/v1/draws")
        .with(
          query: { "date" => "12/03/2026", "loteria_id" => "3" },
          headers: { "APIKEY" => api_key }
        )
        .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
    end

    it "returns parsed draw data" do
      result = client.draws(date: date, loteria_id: 3)
      expect(result).to be_an(Array)
      expect(result.first["horario"]).to eq("14:20")
    end

    it "accepts a Date object and formats correctly" do
      expect { client.draws(date: date, loteria_id: 3) }.not_to raise_error
    end
  end

  describe "error handling" do
    context "when the API returns 401" do
      before do
        stub_request(:get, "#{base_url}/open_api/v1/lotteries")
          .with(headers: { "APIKEY" => api_key })
          .to_return(status: 401, body: "error")
      end

      it "raises LotteryApi::Error" do
        expect { client.lotteries }.to raise_error(LotteryApi::Error, /Unauthorized/)
      end
    end

    context "when the API returns 500" do
      before do
        stub_request(:get, "#{base_url}/open_api/v1/lotteries")
          .with(headers: { "APIKEY" => api_key })
          .to_return(status: 500, body: "error")
      end

      it "raises LotteryApi::Error" do
        expect { client.lotteries }.to raise_error(LotteryApi::Error, /Server error/)
      end
    end

    context "when a timeout occurs" do
      before do
        stub_request(:get, "#{base_url}/open_api/v1/lotteries")
          .to_timeout
      end

      it "raises LotteryApi::Error" do
        expect { client.lotteries }.to raise_error(LotteryApi::Error, /timed out/)
      end
    end
  end
end

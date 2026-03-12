require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.1",
      info: {
        title: "Raffle API",
        version: "v1",
        description: "API para gerenciamento de rifas baseadas na Loteria Federal brasileira"
      },
      components: {
        securitySchemes: {
          bearerAuth: {
            type: :http,
            scheme: :bearer,
            bearerFormat: "JWT"
          }
        }
      },
      security: [ { bearerAuth: [] } ],
      servers: [
        { url: "http://localhost:3000", description: "Development" }
      ]
    }
  }

  config.openapi_format = :yaml
end

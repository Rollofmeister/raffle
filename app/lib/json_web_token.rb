class JsonWebToken
  SECRET = Rails.application.secret_key_base
  EXPIRATION = 24.hours

  def self.encode(payload, exp: EXPIRATION.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET, "HS256")
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET, true, algorithm: "HS256")
    decoded.first
  rescue JWT::DecodeError
    nil
  end
end

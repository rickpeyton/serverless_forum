module EasyCognito
  class SignIn
    def self.from(code: nil)
      response = EasyCognito::Http.authorization_code(code: code)
      new(raw: response)
    end

    attr_reader :raw

    def initialize(raw:)
      @raw = raw
    end

    def id_token
      @id_token ||= begin
                      kid = JSON.parse(Base64.decode64(raw["id_token"].split(".")[0]))["kid"]
                      jwk = EasyCognito.jwk["keys"].detect { |jwk| jwk["kid"] == kid }
                      jwko = JSON::JWK.new jwk
                      JSON::JWT.decode raw["id_token"], jwko
                    rescue StandardError
                      {}
                    end
    end

    def to_session
      {
        id_token: id_token
      }
    end

    def valid?
      return false if id_token.dig(:exp).to_i < Time.now.to_i
      return false if id_token.dig(:aud) != EasyCognito.client_id
      return false if id_token.dig(:iss) != iss
      return false if id_token.dig(:token_use) != "id"

      true
    end

  private

    def iss
      "https://cognito-idp.#{EasyCognito.region}.amazonaws.com/"\
      "#{EasyCognito.pool_id}"
    end
  end
end

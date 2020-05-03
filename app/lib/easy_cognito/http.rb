module EasyCognito
  class Http
    def self.authorization_code(code: nil)
      response = HTTP.basic_auth(
        user: EasyCognito.client_id, pass: EasyCognito.client_secret
      ).post(
        "https://#{EasyCognito.host_domain}/oauth2/token",
        form: {
          grant_type: "authorization_code",
          client_id: EasyCognito.client_id,
          code: code,
          redirect_uri: EasyCognito.redirect_uri
        }
      )

      return response.parse if response.status.success?

      EasyCognito.logger.error <<~RESPONSE.strip
        Cognito Response Error
        #{response.inspect}
      RESPONSE

      {}
    end
  end
end

require_relative "easy_cognito/http"
require_relative "easy_cognito/sign_in"
require_relative "easy_cognito/user"

module EasyCognito
  class << self
    attr_accessor :client_id,
                  :client_secret,
                  :host_domain,
                  :jwk,
                  :pool_id,
                  :redirect_uri,
                  :region

    attr_writer :logger

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def sign_in_url
      "https://#{host_domain}/signup?client_id=#{client_id}"\
      "&response_type=code"\
      "&scope=email+openid+profile"\
      "&redirect_uri=#{redirect_uri}"
    end
  end
end

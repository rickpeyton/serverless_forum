module EasyCognito
  class User
    def self.from(session:)
      new(
        cognito_id: session[:easy_cognito][:id_token]["sub"],
        username: session[:easy_cognito][:id_token]["cognito:username"]
      )
    end

    attr_reader :cognito_id
    attr_reader :username

    def initialize(cognito_id:, username:)
      @cognito_id = cognito_id
      @username = username
    end
  end
end

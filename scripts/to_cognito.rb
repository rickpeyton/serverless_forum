require "csv"
require "dry-initializer"
require "pg" # requires postgresql-devel
require "pry"

require 'dotenv'
Dotenv.load('.env.scripts')

class User
  extend Dry::Initializer

  option :email
  option :old_user_id, proc(&:to_i)
  option :username
end

pg_details = {
  host: ENV["DB_HOST"],
  dbname: ENV["DB_NAME"],
  user: ENV["DB_USER"],
  password: ENV["DB_PASSWORD"]
}

pg = PG::Connection.new(pg_details)

query = <<~SQL
  SELECT u.id, u.username, e.email
  FROM users as u
  LEFT JOIN user_emails as e ON u.id = e.id
SQL

results = pg.exec(query)

users = results.map do |result|
  User.new(
    email: result.dig("email"),
    old_user_id: result.dig("id"),
    username: result.dig("username")
  )
end


headers = %w(name given_name family_name middle_name nickname preferred_username profile picture website email email_verified gender birthdate zoneinfo locale phone_number phone_number_verified address updated_at custom:old_user_id cognito:mfa_enabled cognito:username)

cognito_csv = CSV.open("to_cognito.csv", "wb") do |csv|
  csv << headers
  users.each do |user|
    next if user.old_user_id < 1

    csv << [nil, nil, nil, nil, nil, nil, nil, nil, nil, user.email, true, nil, nil, nil, nil, nil, false, nil, nil, user.old_user_id, false, user.username]
  end
end
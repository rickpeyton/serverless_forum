require "aws-sdk-cognitoidentityprovider"
require "dry-initializer"
require "pg"
require "pry"

require_relative "../app/app"

require 'dotenv'
Dotenv.load('scripts/.env.scripts')

@cognito = Aws::CognitoIdentityProvider::Client.new
users = []

class CognitoUser
  extend Dry::Initializer

  option :cognito_id
  option :username
end

def list_users(token: nil)
  @cognito.list_users(user_pool_id: 'us-east-1_REcRmM2yv', pagination_token: token)
end

def create_users(users:)
  users.map do |user|
    cognito_user = CognitoUser.new(
      cognito_id: user.attributes.find { |u| u.name == "sub" }.value,
      username: user.username
    )
    User.find_or_create_by(cognito_user: cognito_user)
  end
end

result = list_users
users.concat(create_users(users: result.users))

loop do
  break if result.pagination_token.blank?

  result = list_users(token: result.pagination_token)
  users.concat(create_users(users: result.users))
end

## Create Posts

pg_details = {
  host: ENV["DB_HOST"],
  dbname: ENV["DB_NAME"],
  user: ENV["DB_USER"],
  password: ENV["DB_PASSWORD"]
}

@pg= PG::Connection.new(pg_details)

post_query = <<~SQL
  SELECT t.id, t.title, t.created_at, t.featured_link, p.raw, u.username
  FROM topics as t
  LEFT JOIN posts as p ON p.topic_id = t.id
  LEFT JOIN users as u ON u.id = t.user_id
  WHERE p.post_number = 1
  AND p.user_id = u.id
  ORDER BY created_at DESC
SQL

results = @pg.exec(post_query)

def satisfy_minimum_length(s)
  length = s.length
  return s if length > 3

  s + ("." * (3 - length))
end

def date_string_to_iso(s)
  DateTime.parse(s).new_offset(0).iso8601
end



def reply_query(topic_id)
  query = <<~SQL
    SELECT p.raw, p.created_at, u.username
    FROM posts as p
    LEFT JOIN users as u ON u.id = p.user_id
    WHERE p.post_number != 1
    AND p.topic_id = #{topic_id}
  SQL
  @pg.exec(query)
end

def create_replies(replies, post, users)
  replies.each do |reply|
    next if reply.dig("raw").length.zero?
    next if reply.dig("username").nil?
    next if reply.dig("username") == "system"
    reply = Reply.new(
      comment: satisfy_minimum_length(reply.dig("raw")),
      created_at: date_string_to_iso(reply.dig("created_at")),
      reply_post_id: post.id,
      user_id: users.find { |u| u.username == reply.dig("username").downcase }.id,
      username: reply.dig("username").downcase
    )
    reply.save
  rescue => e
    binding.pry
  end
end

results.map.with_index do |result, i|
  old_topic_id = result.dig("id")
  begin
    next if %w(system discobot).include? result.dig("username")
    post = Post.new(
      comment: satisfy_minimum_length(result.dig("raw")),
      created_at: date_string_to_iso(result.dig("created_at")),
      title: satisfy_minimum_length(result.dig("title")),
      user_id: users.find { |u| u.username == result.dig("username").downcase }.id,
      username: result.dig("username"),
    )
    puts " #{i} " if (i % 100).zero?
    post.save
    replies = reply_query(old_topic_id)
    create_replies(replies, post, users)
  rescue => e
    binding.pry
  end
end

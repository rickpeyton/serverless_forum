begin
  require "pry"
rescue LoadError; end # rubocop:disable Lint/SuppressedException
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"
require "aws-sdk-dynamodb"
require "dry-initializer"
require "dry-types"
require "dry-validation"
require "http"
require "json/jwt"
require "sinatra/base"

require_relative "customizations"
require_relative "lib/easy_cognito"
require_relative "models/contracts/post_contract"
require_relative "models/contracts/reply_contract"
require_relative "models/page"
require_relative "models/post"
require_relative "models/post_collection"
require_relative "models/reply"
require_relative "models/reply_collection"
require_relative "models/user"
require_relative "views/view_helpers"

class App < Sinatra::Base
  set bind: "0.0.0.0"
  set port: 3000
  set :views, (proc { File.join(root, "views") })
  set :public_folder, (proc { File.join(root, "assets") })

  set :session_secret, ENV.fetch("SESSION_SECRET") { SecureRandom.hex(64) }
  enable :sessions

  EasyCognito.client_id = ENV["COGNITO_CLIENT_ID"]
  EasyCognito.client_secret = ENV["COGNITO_SECRET"]
  EasyCognito.host_domain = ENV["COGNITO_HOST_DOMAIN"]
  EasyCognito.jwk = JSON.parse(Base64.decode64(ENV["COGNITO_JWK"]))
  EasyCognito.pool_id = ENV["COGNITO_POOL_ID"]
  EasyCognito.redirect_uri = ENV["COGNITO_REDIRECT_URI"]
  EasyCognito.region = ENV["COGNITO_REGION"]

  CUSTOM = Customizations.setup
  DB = Aws::DynamoDB::Client.new(endpoint: "http://db:8000") # TODO: Set the endpoint from the ENV

  get "/" do # Post Index
    page = Page.from_params(params[:page])
    @posts = PostCollection.all(limit: 20, page: page)
    @page = Page.new(next_page: @posts.last_evaluated_key)
    erb :index
  end

  get "/post" do # Post Show
    id = params[:id]
    @post = Post.find_by(id: id)
    redirect "/" unless @post.present?

    @replies = ReplyCollection.where(reply_post_id: id)
    erb :post
  end

  get "/post/new" do # Post New
    require_user

    erb :post_new
  end

  post "/post" do # Post Create
    require_user

    post_contract = PostContract.new.call(sanitize_params(params, Post).merge(current_user_params))

    if post_contract.success?
      Post.new(post_contract.to_h).save
      current_user.increment_post_count
      redirect "/"
    else
      @errors = post_contract.errors.to_h
      erb :post_new
    end
  end

  post "/reply" do # Reply Create
    require_user

    reply_contract = ReplyContract.new.call(sanitize_params(params, Reply).merge(current_user_params))

    if reply_contract.success?
      reply = Reply.new(reply_contract.to_h).save
      current_user.increment_reply_count
      redirect "/post?id=#{reply.reply_post_id}"
    elsif !reply_contract.errors.to_h.key?(:reply_post_id)
      @errors = reply_contract.errors.to_h
      @post = Post.find_by(id: reply_contract.to_h[:reply_post_id])
      @replies = ReplyCollection.where(reply_post_id: @post.id)
      erb :post
    else
      redirect "/"
    end
  end

  get "/sessions/new" do
    redirect(EasyCognito.sign_in_url) && return unless params[:code]

    cognito_sign_in = EasyCognito::SignIn.from(code: params[:code])

    if cognito_sign_in.valid?
      session[:easy_cognito] = cognito_sign_in.to_session
      session[:current_user_id] = User.find_or_create_by(cognito_user: EasyCognito::User.from(session: session)).id
      redirect "/"
    else
      redirect EasyCognito.sign_in_url
    end
  end

  def current_user
    @current_user = User.find_by(id: session[:current_user_id]) if session[:current_user_id]
  end

  def current_user_params
    return {} if current_user.blank?

    {
      user_id: current_user.id,
      username: current_user.username
    }
  end

  def require_user
    redirect "sessions/new" unless current_user
  end

  def sanitize_params(parameters, klass)
    parameters.slice(*klass::PARAMETERS).delete_if { |_k, v| v.blank? }.with_indifferent_access.symbolize_keys
  end

  run! if app_file == $PROGRAM_NAME
end

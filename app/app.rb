begin
  require "pry"
rescue LoadError; end # rubocop:disable Lint/SuppressedException
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"
require "aws-sdk-dynamodb"
require "dry-initializer"
require "dry-types"
require "dry-validation"
require "sinatra/base"

require_relative "customizations"
require_relative "models/contracts/post_contract"
require_relative "models/contracts/reply_contract"
require_relative "models/page"
require_relative "models/post"
require_relative "models/post_collection"
require_relative "models/reply"
require_relative "models/reply_collection"
require_relative "views/view_helpers"

class App < Sinatra::Base
  set bind: "0.0.0.0"
  set port: 3000
  set :views, (proc { File.join(root, "views") })
  set :public_folder, (proc { File.join(root, "assets") })

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
    erb :post_new
  end

  post "/post" do # Post Create
    post_contract = PostContract.new.call(sanitize_params(params, Post))

    if post_contract.success?
      Post.new(post_contract.to_h).save
      redirect "/"
    else
      @errors = post_contract.errors.to_h
      erb :post_new
    end
  end

  post "/reply" do # Reply Create
    reply_contract = ReplyContract.new.call(sanitize_params(params, Reply))

    if reply_contract.success?
      reply = Reply.new(reply_contract.to_h).save
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

  def sanitize_params(parameters, klass)
    parameters.slice(*klass::PARAMETERS).delete_if { |_k, v| v.blank? }.with_indifferent_access.symbolize_keys
  end

  run! if app_file == $PROGRAM_NAME
end

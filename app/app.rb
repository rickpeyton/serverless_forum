begin
  require "pry"
rescue LoadError; end # rubocop:disable Lint/SuppressedException
require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/indifferent_access"
require "aws-sdk-dynamodb"
require "dry-initializer"
require "dry-types"
require "ffaker" # TODO: Remove before deploy. This is a development gem
require "sinatra/base"

require_relative "customizations"
require_relative "models/page"
require_relative "models/post"
require_relative "models/post_collection"
require_relative "models/reply"
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
    @replies = Reply.where(reply_post_id: id)
    erb :post
  end

  get "/post/new" do # Post New
    erb :post_new
  end

  post "/post" do # Post Create
    post = Post.new(sanitize_params(params, Post))
    post.save
    redirect "/"
  end

  def sanitize_params(parameters, klass)
    parameters.slice(*klass::PARAMETERS).delete_if { |_k, v| v.blank? }.with_indifferent_access.symbolize_keys
  end

  run! if app_file == $PROGRAM_NAME
end

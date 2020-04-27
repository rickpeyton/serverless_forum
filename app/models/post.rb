class Post
  class << self
    def find_by(id:)
      result = App::DB.query(
        {
          expression_attribute_values: {
            ":v1" => id,
            ":v2" => "post"
          },
          key_condition_expression: "id = :v1 AND item_type = :v2",
          table_name: "items"
        }
      )
      Post.new(result.items.first.symbolize_keys)
    end
  end

  extend Dry::Initializer

  PARAMETERS = %w(
    comment
    reply_count
    created_at
    id
    item_type
    title
    url
    user_name
  ).freeze
  URL_FORMAT = %r{(https|http)://(\w+.\w+$|\w+.\w+.\w+$)}i.freeze

  option :comment, type: Dry::Types["string"].constrained(min_size: 3), optional: true
  option :reply_count, default: proc { 0.0 }
  option :created_at, default: proc { DateTime.now.new_offset(0).iso8601 }
  option :id, default: proc { SecureRandom.uuid }
  option :item_type, default: proc { "post" }
  option :title, type: Dry::Types["string"].constrained(min_size: 3)
  option :url, type: Dry::Types["string"].constrained(format: URL_FORMAT), optional: true
  option :user_name, default: proc { "Anonymous User" }

  def reply_count_int
    reply_count.to_i
  end

  def created_at_epoch
    created_at_datetime.to_time.to_i
  end

  def save
    App::DB.put_item(
      {
        item: post_params,
        table_name: "items"
      }
    )
  end

private

  def created_at_datetime
    DateTime.parse(created_at)
  end

  def post_params
    Post.dry_initializer.public_attributes(self).compact
  end
end

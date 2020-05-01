class Reply
  extend Dry::Initializer

  PARAMETERS = %w(
    comment
    reply_post_id
  ).freeze

  option :comment, type: Dry::Types["string"].constrained(min_size: 3), optional: true
  option :created_at, default: proc { DateTime.now.new_offset(0).iso8601 }
  option :id, default: proc { SecureRandom.uuid }
  option :item_type, default: proc { "reply" }
  option :reply_post_id
  option :user_name, default: proc { "Anonymous User" }

  def created_at_epoch
    created_at_datetime.to_time.to_i
  end

  def save
    App::DB.put_item(
      item: reply_params,
      table_name: "items"
    )
    Post.find_by(id: reply_post_id).increment_reply_count
    self
  end

private

  def created_at_datetime
    DateTime.parse(created_at)
  end

  def reply_params
    Reply.dry_initializer.public_attributes(self).compact
  end
end

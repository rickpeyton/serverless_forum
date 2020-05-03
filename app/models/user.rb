class User
  class << self
    def find_by(id:)
      result = App::DB.query(
        {
          expression_attribute_values: {
            ":v1" => id,
            ":v2" => "user"
          },
          key_condition_expression: "id = :v1 AND item_type = :v2",
          table_name: "items"
        }
      )

      new(result.items.first.symbolize_keys)
    end

    def find_or_create_by(cognito_user:)
      result = App::DB.query(
        {
          expression_attribute_values: {
            ":v1" => cognito_user.cognito_id,
            ":v2" => "user"
          },
          index_name: "item_type-cognito_id-index",
          key_condition_expression: "cognito_id = :v1 AND item_type = :v2",
          table_name: "items"
        }
      )

      if result.items.first.nil?
        new(
          username: cognito_user.username,
          cognito_id: cognito_user.cognito_id
        ).save
      else
        new(result.items.first.symbolize_keys)
      end
    end
  end

  extend Dry::Initializer

  option :id, default: proc { SecureRandom.uuid }
  option :cognito_id
  option :created_at, default: proc { DateTime.now.new_offset(0).iso8601 }
  option :item_type, default: proc { "user" }
  option :post_count, default: proc { 0.0 }
  option :reply_count, default: proc { 0.0 }
  option :username

  def increment_post_count
    result = App::DB.update_item(
      {
        key: {
          item_type: "user",
          id: id
        },
        expression_attribute_names: {
          "#PC" => "post_count"
        },
        expression_attribute_values: {
          ":pc" => (post_count + 1)
        },
        update_expression: "SET #PC = :pc",
        return_values: "ALL_NEW",
        table_name: "items"
      }
    )
    User.new(result.attributes.symbolize_keys)
  end

  def increment_reply_count
    result = App::DB.update_item(
      {
        key: {
          item_type: "user",
          id: id
        },
        expression_attribute_names: {
          "#RC" => "reply_count"
        },
        expression_attribute_values: {
          ":rc" => (reply_count + 1)
        },
        update_expression: "SET #RC = :rc",
        return_values: "ALL_NEW",
        table_name: "items"
      }
    )
    User.new(result.attributes.symbolize_keys)
  end

  def save
    App::DB.put_item(
      {
        item: user_params,
        table_name: "items"
      }
    )
    self
  end

private

  def user_params
    User.dry_initializer.public_attributes(self).compact
  end
end

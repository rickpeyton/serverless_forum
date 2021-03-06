require "active_support/core_ext/hash/indifferent_access"
require "aws-sdk-dynamodb"
require "date"
require "ffaker"
require "json"
require "pry"

db = Aws::DynamoDB::Client.new(
  endpoint: "http://db:8000"
)

db.delete_table(table_name: "items") if db.list_tables.table_names.any?("items")

items_table = {
  attribute_definitions: [
    {
      attribute_name: "created_at",
      attribute_type: "S"
    },
    {
      attribute_name: "id",
      attribute_type: "S"
    },
    {
      attribute_name: "reply_post_id",
      attribute_type: "S"
    },
    {
      attribute_name: "item_type",
      attribute_type: "S"
    },
    {
      attribute_name: "cognito_id",
      attribute_type: "S"
    }
  ],
  table_name: "items",
  key_schema: [
    {
      attribute_name: "item_type",
      key_type: "HASH"
    },
    {
      attribute_name: "id",
      key_type: "RANGE"
    }
  ],
  provisioned_throughput: {
    read_capacity_units: 5,
    write_capacity_units: 5
  },
  local_secondary_indexes: [
    {
      index_name: "item_type-created_at-index",
      key_schema: [
        {
          attribute_name: "item_type",
          key_type: "HASH"
        },
        {
          attribute_name: "created_at",
          key_type: "RANGE"
        }
      ],
      projection: {
        projection_type: "ALL"
      }
    },
    {
      index_name: "item_type-reply_post_id-index",
      key_schema: [
        {
          attribute_name: "item_type",
          key_type: "HASH"
        },
        {
          attribute_name: "reply_post_id",
          key_type: "RANGE"
        }
      ],
      projection: {
        projection_type: "ALL"
      }
    },
    {
      index_name: "item_type-cognito_id-index",
      key_schema: [
        {
          attribute_name: "item_type",
          key_type: "HASH"
        },
        {
          attribute_name: "cognito_id",
          key_type: "RANGE"
        }
      ],
      projection: {
        projection_type: "ALL"
      }
    }
  ]
}

db.create_table(items_table)

10.times do
  db.put_item(
    {
      item: {
        id: SecureRandom.uuid,
        cognito_id: SecureRandom.hex(8),
        created_at: Time.at(Time.now.utc - rand(259_200..31_536_000)).to_datetime.iso8601,
        item_type: "user",
        post_count: 0.0,
        reply_count: 0.0,
        username: FFaker::Internet.user_name
      },
      table_name: "items"
    }
  )
end

users = db.query(
  {
    expression_attribute_values: {
      ":v1" => "user"
    },
    key_condition_expression: "item_type = :v1",
    table_name: "items"
  }
).items

users = users.map(&:with_indifferent_access)

50.times do
  user = users.sample
  db.put_item(
    {
      item: {
        comment: FFaker::Lorem.sentence,
        created_at: Time.at(Time.now.utc - rand(0..259_200)).to_datetime.iso8601,
        id: SecureRandom.uuid,
        title: FFaker::Lorem.sentence,
        item_type: "post",
        link: FFaker::Internet.http_url,
        username: user[:username],
        user_id: user[:id]
      },
      table_name: "items"
    }
  )

  user_post_count = user[:post_count] += 1

  db.update_item(
    {
      key: {
        item_type: "user",
        id: user[:id]
      },
      expression_attribute_names: {
        "#PC" => "post_count"
      },
      expression_attribute_values: {
        ":pc" => user_post_count
      },
      update_expression: "SET #PC = :pc",
      return_values: "ALL_NEW",
      table_name: "items"
    }
  )
end

posts = db.query(
  {
    expression_attribute_values: {
      ":v1" => "post"
    },
    key_condition_expression: "item_type = :v1",
    table_name: "items"
  }
).items

posts.each do |post|
  replies = rand(0..10)
  post = post.with_indifferent_access.symbolize_keys
  post_id = post[:id]
  post_created_at_epoch = DateTime.parse(post[:created_at]).to_time.to_i

  replies.times do
    user = users.sample
    db.put_item(
      {
        item: {
          comment: FFaker::Lorem.sentence,
          created_at: Time.at(rand(post_created_at_epoch..Time.now.to_i)).to_datetime.iso8601,
          reply_post_id: post_id,
          id: SecureRandom.uuid,
          item_type: "reply",
          username: user[:username],
          user_id: user[:id]
        },
        table_name: "items"
      }
    )

    user_reply_count = user[:reply_count] += 1
    db.update_item(
      {
        key: {
          item_type: "user",
          id: user[:id]
        },
        expression_attribute_names: {
          "#RC" => "reply_count"
        },
        expression_attribute_values: {
          ":rc" => user_reply_count
        },
        update_expression: "SET #RC = :rc",
        return_values: "ALL_NEW",
        table_name: "items"
      }
    )
  end

  db.update_item(
    {
      key: {
        item_type: "post",
        id: post_id
      },
      expression_attribute_names: {
        "#RC" => "reply_count"
      },
      expression_attribute_values: {
        ":rc" => replies
      },
      update_expression: "SET #RC = :rc",
      return_values: "ALL_NEW",
      table_name: "items"
    }
  )
end

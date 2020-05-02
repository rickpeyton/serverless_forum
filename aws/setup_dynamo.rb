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
    }
  ]
}

db.create_table(items_table)

# Create Posts
50.times do
  db.put_item(
    {
      item: {
        comment: FFaker::Lorem.sentence,
        created_at: Time.at(Time.now.utc - rand(0..259_200)).to_datetime.iso8601,
        id: SecureRandom.uuid,
        title: FFaker::Lorem.sentence,
        item_type: "post",
        link: FFaker::Internet.http_url,
        user_name: FFaker::Internet.user_name
      },
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

# Add replies to posts
posts.each do |post|
  replies = rand(0..10)
  post = post.with_indifferent_access.symbolize_keys
  post_id = post[:id]
  post_created_at_epoch = DateTime.parse(post[:created_at]).to_time.to_i

  replies.times do
    db.put_item(
      {
        item: {
          comment: FFaker::Lorem.sentence,
          created_at: Time.at(rand(post_created_at_epoch..Time.now.to_i)).to_datetime.iso8601,
          reply_post_id: post_id,
          id: SecureRandom.uuid,
          item_type: "reply",
          user_name: FFaker::Internet.user_name
        },
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

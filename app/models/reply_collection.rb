class ReplyCollection
  class << self
    def where(reply_post_id:)
      result = App::DB.query(
        {
          expression_attribute_values: {
            ":v1" => reply_post_id,
            ":v2" => "reply"
          },
          key_condition_expression: "reply_post_id = :v1 AND item_type = :v2",
          index_name: "item_type-reply_post_id-index",
          table_name: "items"
        }
      )
      new(replies: result.items.map { |reply| Reply.new(reply.symbolize_keys) })
    end
  end

  include Enumerable

  def initialize(replies:)
    @replies = replies
  end

  def each
    @replies.sort_by(&:created_at).each do |reply|
      yield reply
    end
  end
end

class PostCollection
  class << self
    def all(limit:, page:)
      result = App::DB.query(
        {
          expression_attribute_values: {
            ":v1" => "post"
          },
          key_condition_expression: "item_type = :v1",
          table_name: "items",
          index_name: "item_type-created_at-index",
          limit: limit,
          scan_index_forward: false,
          exclusive_start_key: page.next_page
        }
      )
      new(posts: result.items.map { |post| Post.new(post.symbolize_keys) },
          last_evaluated_key: result.last_evaluated_key)
    end
  end

  include Enumerable
  attr_reader :last_evaluated_key

  def initialize(posts:, last_evaluated_key:)
    @posts = posts
    @last_evaluated_key = last_evaluated_key
  end

  def each
    @posts.each do |post|
      yield post
    end
  end
end

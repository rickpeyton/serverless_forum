class ReplyContract < Dry::Validation::Contract
  params do
    required(:comment).value(:string)
    required(:reply_post_id).value(:string)
  end

  rule(:comment) do
    key.failure("must be greater than 3 characters") if value.length <= 3
  end

  rule(:reply_post_id) do
    key.failure("must exist") unless Post.find_by(id: value)&.id == value
  end
end

class ReplyContract < Dry::Validation::Contract
  params do
    required(:comment).value(:string)
    required(:reply_post_id).value(:string)
  end

  rule(:comment) do
    key.failure("must be greater than 3 characters") if key? && value.length <= 3
  end
end

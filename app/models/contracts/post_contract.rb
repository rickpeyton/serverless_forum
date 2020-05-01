class PostContract < Dry::Validation::Contract
  params do
    optional(:comment).value(:string)
    required(:title).value(:string)
    optional(:url).value(:string)
  end

  rule(:comment) do
    key.failure("must be greater than 3 characters") if key? && value.length <= 3
  end

  rule(:comment, :url) do
    key.failure("must be added if url is empty") if values[:comment].nil? && values[:url].nil?
  end

  rule(:title) do
    key.failure("must be greater than 3 characters") if value.length <= 3
  end

  rule(:url) do
    key.failure("has invalid format") if key? && !%r{(https|http)://(\w+.\w+$|\w+.\w+.\w+)}i.match?(value)
  end
end

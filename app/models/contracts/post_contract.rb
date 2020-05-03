class PostContract < Dry::Validation::Contract
  params do
    optional(:comment).value(:string)
    optional(:link).value(:string)
    required(:title).value(:string)
    required(:user_id).value(:string)
    required(:username).value(:string)
  end

  rule(:comment) do
    key.failure("must be greater than 3 characters") if key? && value.length <= 3
  end

  rule(:comment, :link) do
    key.failure("must be added if link is empty") if values[:comment].nil? && values[:link].nil?
  end

  rule(:title) do
    key.failure("must be greater than 3 characters") if value.length <= 3
  end

  rule(:link) do
    key.failure("has invalid format") if key? && !%r{(https|http)://(\w+.\w+$|\w+.\w+.\w+)}i.match?(value)
  end

  rule(:link) do
    key.failure("is not working") if key? && !PostContract.link_works?(value)
  end

  def self.link_works?(link)
    response = HTTP.follow.get(link)
    response.status.success?
  rescue HTTP::Error
    false
  end
end

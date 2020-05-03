RSpec.describe ReplyContract do
  it "must have a comment" do
    actual = ReplyContract.new.call({})

    expect(actual.errors.to_h[:comment]).to include "is missing"
  end

  it "must have a comment greater than 3 characters" do
    actual = ReplyContract.new.call(comment: "123")

    expect(actual.errors.to_h[:comment]).to include "must be greater than 3 characters"
  end

  it "is success if the comment is valid" do
    valid_post = instance_double(Post, id: "valid")
    allow(Post).to receive(:find_by).and_return(valid_post)

    actual = ReplyContract.new.call(required_params)

    expect(actual).to be_success
  end

  it "must have a reply_post_id" do
    actual = ReplyContract.new.call({})

    expect(actual.errors.to_h[:reply_post_id]).to include "is missing"
  end

  it "must have a post with the given id" do
    actual = ReplyContract.new.call(reply_post_id: "invalid")

    expect(actual.errors.to_h[:reply_post_id]).to include "must exist"
  end

  def required_params
    {
      comment: "valid",
      reply_post_id: "valid",
      user_id: "valid",
      username: "valid_username"
    }
  end
end

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
    actual = ReplyContract.new.call(comment: "valid")

    expect(actual).to be_success
  end
end
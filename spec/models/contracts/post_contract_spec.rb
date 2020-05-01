RSpec.describe PostContract do
  it "requires a title" do
    actual = PostContract.new.call(comment: "valid", url: "http://valid.com")

    expect(actual.errors.to_h[:title]).to include "is missing"
  end

  it "must have a title 3 characters or more" do
    actual = PostContract.new.call(title: "123", comment: "valid", url: "http://valid.com")

    expect(actual.errors.to_h[:title]).to include "must be greater than 3 characters"
  end

  it "must have a comment greater than 3 characters if it has one" do
    actual = PostContract.new.call(title: "valid", comment: "123")

    expect(actual.errors.to_h[:comment]).to include "must be greater than 3 characters"
  end

  it "must have a valid url if it has one" do
    actual = PostContract.new.call(title: "valid", url: "invalid.com")

    expect(actual.errors.to_h[:url]).to include "has invalid format"
  end

  it "must have a comment if there is no url" do
    actual = PostContract.new.call(title: "valid")

    expect(actual.errors.to_h[:comment]).to include "must be added if url is empty"
  end

  it "does not have to have a comment if it has a url" do
    actual = PostContract.new.call(title: "valid", url: "http://valid.com")

    expect(actual).to be_success
  end

  it "does not have to have a url if it has a comment" do
    actual = PostContract.new.call(title: "valid", comment: "valid")

    expect(actual).to be_success
  end

  it "is successful when valid" do
    actual = PostContract.new.call(title: "valid", url: "https://valid.com", comment: "valid")

    expect(actual).to be_success
  end
end
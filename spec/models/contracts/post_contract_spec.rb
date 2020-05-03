RSpec.describe PostContract do
  include WebmockStubs

  it "requires a title" do
    stub_valid_link

    actual = PostContract.new.call(comment: "valid", link: "http://valid.com")

    expect(actual.errors.to_h[:title]).to include "is missing"
  end

  it "must have a title 3 characters or more" do
    stub_valid_link

    actual = PostContract.new.call(title: "123", comment: "valid", link: "http://valid.com")

    expect(actual.errors.to_h[:title]).to include "must be greater than 3 characters"
  end

  it "must have a comment greater than 3 characters if it has one" do
    actual = PostContract.new.call(title: "valid", comment: "123")

    expect(actual.errors.to_h[:comment]).to include "must be greater than 3 characters"
  end

  it "must have a valid link if it has one" do
    actual = PostContract.new.call(title: "valid", link: "invalid.com")

    expect(actual.errors.to_h[:link]).to include "has invalid format"
  end

  it "must have a comment if there is no link" do
    actual = PostContract.new.call(title: "valid")

    expect(actual.errors.to_h[:comment]).to include "must be added if link is empty"
  end

  it "does not need a comment if it has a link" do
    stub_valid_link

    actual = PostContract.new.call(required_params)

    expect(actual).to be_success
  end

  it "does not have to have a link if it has a comment" do
    actual = PostContract.new.call(title: "valid", user_id: "123", username: "abc", comment: "valid")

    expect(actual).to be_success
  end

  it "is successful when valid" do
    stub_valid_link

    actual = PostContract.new.call(required_params.merge(comment: "valid"))

    expect(actual).to be_success
  end

  it "checks if a link returns a successful response" do
    allow(PostContract).to receive(:link_works?).and_return(true)

    actual = PostContract.new.call(required_params)

    expect(actual).to be_success
  end

  it "does not allow a link that is not returning a success" do
    allow(PostContract).to receive(:link_works?).and_return(false)

    actual = PostContract.new.call(title: "valid", link: "http://invalid.com")

    expect(actual.errors.to_h[:link]).to include "is not working"
  end

  def required_params
    {
      title: "valid",
      link: "http://valid.com",
      user_id: "123",
      username: "abc"
    }
  end
end

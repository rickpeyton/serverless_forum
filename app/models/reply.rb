class Reply
  class << self
    def where(reply_post_id:)
      [].tap do |a|
        20.times { a << Reply.new }
      end.sort_by(&:created_at)
    end
  end

  attr_accessor :user_name
  attr_accessor :created_at
  attr_accessor :comment

  def initialize
    self.user_name = FFaker::Internet.user_name
    self.created_at = Time.at(Time.now.utc - rand(0..259_200)).to_datetime
    self.comment = FFaker::Lorem.sentence
  end
end

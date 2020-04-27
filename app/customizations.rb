class Customizations
  class << self
    def setup
      new(
        logo: ENV["LOGO"],
        title: ENV["TITLE"]
      )
    end
  end

  attr_reader :logo
  attr_reader :title

  def initialize(logo:, title:)
    @logo = logo
    @title = title
  end
end

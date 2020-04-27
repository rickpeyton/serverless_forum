class Page
  class << self
    def from_params(params)
      params = Base64.urlsafe_decode64(params.to_s)
      params = params.blank? ? nil : JSON.parse(params).with_indifferent_access.symbolize_keys
      new(params)
    end
  end

  extend Dry::Initializer

  option :next_page, optional: true

  def encoded_next
    Base64.urlsafe_encode64({ next_page: next_page }.to_json)
  end
end

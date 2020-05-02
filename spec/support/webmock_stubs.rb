module WebmockStubs
  def stub_valid_link
    stub_request(:get, "http://valid.com/")
      .with(
        headers: {
          "Connection" => "close",
          "Host" => "valid.com",
          "User-Agent" => "http.rb/4.4.1"
        }
      )
      .to_return(status: 200, body: "", headers: {})
  end
end

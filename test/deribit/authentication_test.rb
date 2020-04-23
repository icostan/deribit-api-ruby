require 'minitest_helper'

class Deribit::AuthenticationTest < Minitest::Test
  def setup
    @authentication = Deribit::Authentication.new nil, ENV['API_KEY'], ENV['API_SECRET']
  end

  def test_signature
    env = {
      'method' => 'get',
      'url' => URI.parse('https://test.com/api/v2/private/get_account_summary?currency=BTC'),
      'body' => ''
    }
    timestamp = 1586962148000
    nonce = 't52ep048'

    signature = @authentication.header env, timestamp, nonce
    assert_equal "deri-hmac-sha256 id=#{ENV['API_KEY']},ts=#{timestamp},sig=515f6f48629d424c9e515cf0baeb4d0228d260fd19066fbd6a71ff76c7f293d6,nonce=#{nonce}", signature
  end
end

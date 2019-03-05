require 'minitest_helper'

class Deribit::AuthenticationTest < Minitest::Test
  def setup
    @authentication = Deribit::Authentication.new nil, '2YZn85siaUf5A', 'BTMSIAJ8IYQTAV4MLN88UAHLIUNYZ3HN'
  end

  def test_signature
    env = {
      'url' => URI.parse('http://test.com/api/v1/private/buy'),
      'body' => '{"instrument": "BTC-15JAN16", "price": 500, "quantity": 1}'
    }
    signature = @authentication.signature env, 1452237485895
    assert_equal '2YZn85siaUf5A.1452237485895.KOlc7ELGnz8cjYp614ONxZlngo/z2AHMEjVdlHlW9Oo=', signature
  end
end

require 'minitest_helper'

class Deribit::ClientTest < Minitest::Test
  def setup
    @client = Deribit::Client.new testnet: true
  end

  def test_time_http
    time = @client.time
    assert time.positive?
  end

  def test_time_websocket
    @client.time do |time|
      assert time.positive?
      @client.websocket.stop
    end
  end

  def test_enable_heartbeat_websocket
    @client.enable_heartbeat do |success|
      assert_equal 'ok', success
      @client.websocket.stop
    end
  end

  # def test_cancel_heartbeat_websocket
  #   @client.cancel_heartbeat do |success|
  #     assert_equal 'ok', success
  #     @client.websocket.stop
  #   end
  # end

  def test_test_http
    test = @client.test
    assert test.success
    assert test.testnet
  end

  def test_test_websocket
    @client.test do |success|
      assert_includes success, 'test'
      @client.websocket.stop
    end
  end

  def test_ping_http
    pong = @client.ping
    assert_equal 'pong', pong
  end

  def test_ping_websocket
    @client.ping do |pong|
      assert_equal 'pong', pong
      @client.websocket.stop
    end
  end

  def test_instruments_http
    instruments = @client.instruments
    assert instruments.size.positive?
    instrument = instruments.first
    assert_equal 'option', instrument.kind
    assert_includes instrument.instrumentName, 'BTC'
  end

  def test_instruments_websocket
    @client.instruments do |instrument|
      assert_equal 'USD', instrument.currency
      @client.websocket.stop
    end
  end

  def test_currencies_http
    currencies = @client.currencies
    assert currencies.size.positive?
    currency = currencies.first
    assert_equal 'BTC', currency.currency
    assert currency.minConfirmation >= 1
  end

  def test_currencies_websocket
    @client.currencies do |currency|
      assert currency.minConfirmation.positive?
      assert currency.txFee.positive?
      @client.websocket.stop
    end
  end

  def test_index_http
    index = @client.index 'ETH'
    assert index.eth.positive?
    assert index.edp.positive?
  end

  def test_index_websocket
    @client.index 'BTC' do |index|
      assert index.btc.positive?
      @client.websocket.stop
    end
  end

  def test_orderbook_http
    orderbook = @client.orderbook 'BTC-PERPETUAL', depth: 3
    assert_equal 'BTC-PERPETUAL', orderbook.instrument
    assert_equal 3, orderbook.bids.size
    assert_equal 3, orderbook.asks.size
  end

  def test_orderbook_websocket
    @client.orderbook 'ETH-PERPETUAL', depth: 3 do |orderbook|
      assert_equal 'ETH-PERPETUAL', orderbook.instrument
      assert_equal 3, orderbook.bids.size
      assert_equal 3, orderbook.asks.size
      @client.websocket.stop
    end
  end

  def test_trades_http
    trades = @client.trades 'options', count: 3
    assert_equal 3, trades.size
    trade = trades.first
    assert trade.price.positive?
    assert trade.quantity.positive?
    assert trade.iv.positive?
  end

  def test_trades_websocket
    @client.trades do |trade|
      assert trade.price.positive?
      assert trade.quantity.positive?
      @client.websocket.stop
    end
  end

  def test_summary_http
    summaries = @client.summary :futures
    summary = summaries.first
    assert summary.openInterest.positive?
    assert summary.volume.positive?
    assert summary.volumeBtc.positive?
  end

  def test_summary_websocket
    @client.summary do |summary|
      assert summary.instrumentName
      @client.websocket.stop
    end
  end

  def test_stats_http
    stats = @client.stats
    assert_kind_of Hash, stats
    btcusd = stats.btc_usd
    assert btcusd.futuresVolume.positive?
    assert btcusd.callsVolume.positive?
    assert btcusd.putsVolume.positive?
  end

  def test_stats_websocket
    @client.stats do |stats|
      btcusd = stats.btc_usd
      assert btcusd.futuresVolume.positive?
      assert btcusd.callsVolume.positive?
      assert btcusd.putsVolume.positive?
      @client.websocket.stop
    end
  end

  def  test_announcements_http
    announcements = @client.announcements
    assert announcements.size.positive?
    assert !announcements.first.title.nil?
  end

  def test_announcements_websocket
    @client.announcements do |announcement|
      assert !announcement.title.nil?
      @client.websocket.stop
    end
  end

  def test_settlements_http
    settlements = @client.settlements
    assert !settlements.continuation.nil?
    assert settlements.settlements.size.positive?
    assert settlements.settlements.first.indexPrice.positive?
  end

  def test_settlements_websocket
    @client.settlements do |settlements|
      assert !settlements.continuation.nil?
      assert settlements.settlements.size.positive?
      assert settlements.settlements.first.indexPrice.positive?
      @client.websocket.stop
    end
  end

  class PrivateTests < Minitest::Test
    def  setup
      @client = Deribit::Client.new key: ENV['API_KEY'], secret: ENV['API_SECRET'], testnet: true, debug: false
    end

    def test_account
      account = @client.account
      assert account.equity.positive?
    end

    def test_buy
      response = @client.buy 'BTC-PERPETUAL', 10, price: 2500
      assert response.order.quantity.positive?
      assert_equal 'open', response.order.state
      assert_empty response.trades

      @client.cancel response.order.orderId
    end

    def test_sell
      response = @client.sell 'BTC-PERPETUAL', 10, price: 5500
      assert response.order.quantity.positive?
      assert_equal 'open', response.order.state
      assert_empty response.trades

      @client.cancelall
    end

    def test_edit
      response = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      response = @client.edit response.order.orderId, 5, 1500
      assert_equal 5, response.order.quantity
      assert_equal 1500, response.order.price
      assert_equal 'open', response.order.state

      @client.cancel response.order.orderId
    end

    def test_cancel
      response = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      response = @client.cancel response.order.orderId
      assert_equal 'cancelled', response.order.state
    end

    def test_orders
      @client.buy 'BTC-PERPETUAL', 9, price: 1000
      orders = @client.orders
      assert_equal 1, orders.size
      assert_equal 9, orders.first.quantity

      @client.cancelall
    end

    def test_positions
      positions = @client.positions
      assert_empty positions
    end

    def test_orderhistory
      history = @client.orders_history
      assert_equal 2, history.size
    end

    def test_orderdetails
      order = @client.order '2175131427'
      assert_equal 'filled', order.state
    end

    def test_trades_history
      skip 'it fails on testnet even if there are history trades '
      trades = @client.trades_history :all, startTimestamp: Time.new(2019, 3, 1).to_i
      assert trades.size.positive?
    end

    def test_new_announcements
      announcements = @client.new_announcements
      assert_empty announcements
    end

    def test_settlements_history
      response = @client.settlements_history
      assert response.settlements.size.positive?
      assert_equal 'settlement', response.settlements.first.type
    end
  end
end

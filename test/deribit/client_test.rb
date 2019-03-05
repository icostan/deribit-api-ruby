require 'minitest_helper'

class Deribit::ClientTest < Minitest::Test
  def setup
    @client = Deribit::Client.new testnet: true
  end

  def test_time
    time = @client.time
    assert time.positive?
  end

  def test_ttt
    test = @client.test
    # assert test.success
    # assert test.testnet
  end

  def test_ping
    pong = @client.ping
    assert_equal 'pong', pong
  end

  def test_instruments
    instruments = @client.instruments
    assert instruments.size.positive?
    instrument = instruments.first
    assert_equal 'option', instrument.kind
    assert_includes instrument.instrumentName, 'BTC'
  end

  def test_currencies
    currencies = @client.currencies
    assert currencies.size.positive?
    currency = currencies.first
    assert_equal 'BTC', currency.currency
    assert currency.minConfirmation >= 1
  end

  def test_index
    index = @client.index
    assert index.btc.positive?
    assert index.edp.positive?
  end

  def test_orderbook
    orderbook = @client.orderbook 'BTC-PERPETUAL', depth: 3
    assert_equal 'BTC-PERPETUAL', orderbook.instrument
    assert_equal 3, orderbook.bids.size
    assert_equal 3, orderbook.asks.size
  end

  def test_trades
    trades = @client.trades 'options', count: 3
    assert_equal 3, trades.size
    trade = trades.first
    assert trade.price.positive?
    assert trade.quantity.positive?
    assert trade.iv.positive?
  end

  def test_summary
    summaries = @client.summary :futures
    summary = summaries.first
    assert summary.openInterest.positive?
    assert summary.volume.positive?
    assert summary.volumeBtc.positive?
  end

  def test_stats
    stats = @client.stats
    assert_kind_of Hash, stats
    btcusd = stats.btc_usd
    assert btcusd.futuresVolume.positive?
    assert btcusd.callsVolume.positive?
    assert btcusd.putsVolume.positive?
  end

  def  test_announcements
    announcements = @client.announcements
    assert announcements.size.positive?
    assert !announcements.first.title.nil?
  end

  def test_settlements
    skip 'it fails on testnet, method was removed?'
    settlements = @client.settlements
    assert settlements.size.positive?
    assert settlements.first.indexPrice.positive?
  end


  class PrivateTests < Minitest::Test
    def  setup
      @client = Deribit::Client.new key: ENV['API_KEY'], secret: ENV['API_SECRET'], testnet: true
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
      trades = @client.trades_history
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

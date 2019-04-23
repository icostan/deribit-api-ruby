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

  def test_announcements_http
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

    def test_account_http
      account = @client.account
      assert account.equity.positive?
    end

    def test_account_websocket
      @client.account do |account|
        assert account.equity.positive?
        @client.websocket.stop
      end
    end

    def test_buy_http
      result = @client.buy 'BTC-PERPETUAL', 10, price: 2500
      assert result.order.quantity.positive?
      assert_equal 'open', result.order.state
      assert_empty result.trades

      @client.cancel result.order.orderId
    end

    def test_buy_websocket
      @client.buy 'BTC-PERPETUAL', 10, price: 2500 do |result|
        assert result.order.quantity.positive?
        assert_equal 'open', result.order.state
        assert_empty result.trades
        @client.websocket.stop
      end
    end

    def test_sell_http
      result = @client.sell 'BTC-PERPETUAL', 10, price: 7500
      assert result.order.quantity.positive?
      assert_equal 'open', result.order.state
      assert_empty result.trades

      @client.cancelall
    end

    def test_sell_websocket
      @client.sell 'BTC-PERPETUAL', 10, price: 7500 do |result|
        assert result.order.quantity.positive?
        assert_equal 'open', result.order.state
        assert_empty result.trades
        @client.cancelall
        @client.websocket.stop
      end
    end

    def test_edit_http
      result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      result = @client.edit result.order.orderId, 5, 1500
      assert_equal 5, result.order.quantity
      assert_equal 1500, result.order.price
      assert_equal 'open', result.order.state

      @client.cancel result.order.orderId
    end

    def test_edit_websocket
      result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      @client.edit result.order.orderId, 5, 1500 do |result|
        assert_equal 5, result.order.quantity
        assert_equal 1500, result.order.price
        assert_equal 'open', result.order.state
        @client.cancel result.order.orderId

        @client.websocket.stop
      end
    end

    def test_cancel_http
      result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      result = @client.cancel result.order.orderId
      assert_equal 'cancelled', result.order.state
    end

    def test_cancel_websocket
      result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
      @client.cancel result.order.orderId do |result|
        assert_equal 'cancelled', result.order.state

        @client.websocket.stop
      end
    end

    def test_cancelall_http
      @client.buy 'BTC-PERPETUAL', 7, price: 1000
      result = @client.cancelall
      assert result
    end

    def test_cancelall_websocket
      @client.buy 'BTC-PERPETUAL', 8, price: 1000
      @client.cancelall do |result|
        assert result

        @client.websocket.stop
      end
    end

    def test_orders_http
      @client.buy 'BTC-PERPETUAL', 9, price: 1000
      orders = @client.orders
      assert_equal 1, orders.size
      assert_equal 9, orders.first.quantity

      @client.cancelall
    end

    def test_orders_websocket
      @client.buy 'BTC-PERPETUAL', 9, price: 1000
      @client.orders do |order|
        assert_equal 9, order.quantity

        @client.cancelall
        @client.websocket.stop
      end
    end

    def test_positions_http
      positions = @client.positions
      assert_empty positions
    end

    # TODO: need a testing position
    # def test_positions_websocket
    #   @client.positions do |position|
    #     assert_empty position
    #     @client.websocket.stop
    #   end
    # end

    def test_orderhistory_http
      history = @client.orders_history
      assert_equal 8, history.size
    end

    def test_orderhistory_websocket
      @client.orders_history do |order|
        assert order.amount.positive?
        @client.websocket.stop
      end
    end

    def test_orderstate_http
      order = @client.order '2175131427'
      assert_equal 'filled', order.state
    end

    def test_orderstate_websocket
      @client.order '2175131427' do |order|
        assert_equal 'filled', order.state
        @client.websocket.stop
      end
    end

    def test_trades_history_http
      # skip 'it fails on testnet even if there are history trades '
      trades = @client.trades_history :all, startTimestamp: Time.new(2019, 3, 1).to_i
      assert trades.size.positive?
    end

    def test_trades_history_websocket
      # skip 'it fails on testnet even if there are history trades '
      @client.trades_history :all, startTimestamp: Time.new(2019, 3, 1).to_i do |trade|
        assert trade.size.positive?
        @client.websocket.stop
      end
    end

    def test_new_announcements_http
      announcements = @client.new_announcements
      assert_empty announcements
    end

    def test_new_announcements_websocket
      skip 'need testing announcement'
      @client.new_announcements do |announcement|
        assert_empty !announcement.title
        @client.websocket.stop
      end
    end

    def test_logout
      @client.logout do |result|
        assert result
        @client.websocket.stop
      end
    end

    def test_cancelon_disconnect
      @client.cancelondisconnect 'disabled' do |result|
        assert result
        @client.websocket.stop
      end
    end

    def test_getemaillang_http
      lang = @client.getemaillang
      assert_equal 'en', lang
    end

    def test_getemaillang_websocket
      @client.getemaillang do |lang|
        assert_equal 'en', lang
        @client.websocket.stop
      end
    end

    def test_setemaillang_http
      success = @client.setemaillang 'en'
      assert success
    end

    def test_setemaillang_websocket
      @client.setemaillang 'en' do |success|
        assert success
        @client.websocket.stop
      end
    end

    def test_settlements_history_http
      result = @client.settlements_history
      assert result.settlements.size.positive?
      assert_equal 'settlement', result.settlements.first.type
    end

    def test_settlements_history_websocket
      @client.settlements_history do |result|
        assert result.settlements.size.positive?
        assert_equal 'settlement', result.settlements.first.type
        @client.websocket.stop
      end
    end
  end
end

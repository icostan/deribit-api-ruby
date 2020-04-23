# frozen_string_literal: true

require 'minitest_helper'

class Deribit::ClientTest < Minitest::Test
  def setup
    @client = Deribit::Client.new key: ENV['API_KEY'], secret: ENV['API_SECRET'], testnet: true, debug: false
  end

  def test_user_portofolio_websocket
    @client.websocket.subscribe 'user.portofolio.BTC' do |data|
      assert data.available_funds > 0
    end
    sleep 3
    assert @client.websocket.authorized?
  end

  def test_test_http
    test = @client.http.get '/public/test'
    assert test.version
  end

  def test_ping_http
    pong = @client.http.get '/public/ping'
    assert_equal 'pong', pong
  end

  def test_instruments_http
    instruments = @client.instruments currency: 'ETH', kind: 'future'
    assert instruments.size.positive?
    instrument = instruments.first
    assert_equal 'future', instrument.kind
    assert_includes instrument.instrument_name, 'ETH'
  end

  def test_currencies_http
    currencies = @client.currencies
    assert currencies.size.positive?
    currency = currencies.last
    assert_equal 'BTC', currency.currency
    assert currency.min_confirmations >= 1
  end

  def test_index_http
    index = @client.index currency: 'ETH'
    assert index.ETH.positive?
    assert index.edp.positive?
  end

  def test_book_http
    book = @client.book instrument_name: 'BTC-PERPETUAL', depth: 3
    assert_equal 'BTC-PERPETUAL', book.instrument_name
    assert_equal 3, book.bids.size
    assert_equal 3, book.asks.size
  end

  def test_book_websocket
    @client.book instrument_name: 'ETH-PERPETUAL', group: 1, depth: 3 do |book|
      assert_equal 'ETH-PERPETUAL', book.instrument_name
      assert book.timestamp > 0
    end
    sleep 3
    @client.book do |book|
      assert_equal 'BTC-PERPETUAL', book.instrument_name
      assert book.timestamp > 0
    end
    sleep 1
  end

  class TradesTest < Minitest::Test
    def setup
      @client = Deribit::Client.new key: ENV['API_KEY'], secret: ENV['API_SECRET'], testnet: true, debug: false
    end

    def test_missing_required_arguments
      assert_raises(ArgumentError) do
        @client.trades count: 3
      end
    end

    def test_by_instrument_http
      instrument_name = 'BTC-PERPETUAL'
      trades = @client.trades instrument_name: instrument_name, count: 3
      assert_equal 3, trades.size
      trade = trades.first
      assert_equal instrument_name, trade.instrument_name
      assert trade.price.positive?
      assert trade.amount.positive?
    end

    def test_by_currency_http
      currency = 'ETH'
      trades = @client.trades currency: currency, count: 3
      assert_equal 3, trades.size
      trade = trades.first
      assert_includes trade.instrument_name, currency
      assert trade.price.positive?
      assert trade.amount.positive?
    end

    def test_by_instrument_and_time_http
      instrument_name = 'BTC-PERPETUAL'
      timestamp = (Time.now - 60).to_i * 1000
      trades = @client.trades instrument_name: instrument_name, end_timestamp: timestamp, count: 3
      assert_equal 3, trades.size
      trade = trades.first
      assert_equal instrument_name, trade.instrument_name
      assert trade.timestamp < (Time.now - 60).to_i * 1000
    end

    def test_private_by_instrument_http
      instrument_name = 'BTC-PERPETUAL'
      trades = @client.trades instrument_name: instrument_name, count: 3, private: true
      assert_equal 3, trades.size
    end

    def test_public_by_instrument_websocket
      instrument_name = 'BTC-PERPETUAL'
      @client.trades(instrument_name: instrument_name) do |trade|
        assert_equal instrument_name, trade.instrument_name
        assert trade.price.positive?
        assert trade.amount.positive?
      end
      sleep 10
    end

    def test_private_by_instrument_websocket
      instrument_name = 'BTC-PERPETUAL'
      @client.trades(instrument_name: instrument_name, private: true) do |trade|
        assert_equal instrument_name, trade.instrument_name
        assert trade.price.positive?
        assert trade.amount.positive?
      end
      sleep 10
      assert @client.websocket.authorized?
    end

    def test_by_kind_websocket
      @client.trades(kind: 'future', currency: 'BTC') do |trade|
        assert trade.price.positive?
        assert trade.amount.positive?
      end
      sleep 10
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
    end
    sleep 3
  end

  def test_settlements_http
    settlements = @client.settlements
    assert !settlements.continuation.nil?
    assert settlements.settlements.size.positive?
    assert settlements.settlements.first.index_price.positive?
  end

  def test_account_http
    account = @client.account
    assert account.equity.positive?
  end

  def test_buy_http
    result = @client.buy 'BTC-PERPETUAL', 10, price: 2500
    assert !result.order.order_id.nil?
    assert_equal 10, result.order.amount
    assert_equal 'open', result.order.order_state
    assert_empty result.trades
    @client.cancel result.order.order_id

    sleep 5

    result = @client.buy 'BTC-PERPETUAL', 10, type: :market
    assert !result.order.order_id.nil?
    assert_equal 10, result.order.amount
    assert result.trades.size > 0
    result = @client.close 'BTC-PERPETUAL'
    assert 'filled', result.order.order_state
    assert result.trades.size > 0
  end

  def test_sell_http
    result = @client.sell 'BTC-PERPETUAL', 10, price: 15_000
    assert result.order.amount.positive?
    assert_equal 'open', result.order.order_state
    assert_empty result.trades

    @client.cancel_all
  end

  def test_edit_http
    result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
    result = @client.edit result.order.order_id, 20, 1500
    assert_equal 20, result.order.amount
    assert_equal 1500, result.order.price
    assert_equal 'open', result.order.order_state

    @client.cancel result.order.order_id
  end

  def test_cancel_http
    result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
    result = @client.cancel result.order.order_id
    assert_equal 'cancelled', result.order_state
  end

  def test_cancel_all_http
    @client.buy 'BTC-PERPETUAL', 10, price: 1000
    result = @client.cancel_all currency: 'ETH'
    assert 1, @client.orders.size
    result = @client.cancel_all instrument_name: 'ETH-PERPETUAL'
    assert 1, @client.orders.size
    result = @client.cancel_all
    assert 0, @client.orders.size
  end

  def test_quote_websocket
    quote = @client.quote do |quote|
      assert 'BTC-PERPETUAL', quote.instrument_name
      assert quote.best_ask_price > 0
      assert quote.best_bid_amount > 0
    end
    sleep 1
  end

  def test_ticker_http
    ticker = @client.ticker
    assert 'BTC-PERPETUAL', ticker.instrument_name
    assert ticker.index_price > 0
  end

  def test_ticker_websocket
    ticker = @client.ticker do |ticker|
      assert 'BTC-PERPETUAL', ticker.instrument_name
    end
    sleep 3
  end

  def test_orders_http
    @client.buy 'BTC-PERPETUAL', 10, price: 1000
    orders = @client.orders
    assert_equal 1, orders.size
    assert_equal 10, orders.first.amount
    assert_equal 1000, orders.first.price
    @client.cancel_all
  end

  def test_orders_websocket
    result = @client.buy 'BTC-PERPETUAL', 10, price: 1000
    @client.orders do |order|
      assert_equal 2000, order.price
    end
    @client.edit result.order.order_id, 20, 2000
    sleep 3
    @client.cancel_all
  end

  def test_positions_http
    positions = @client.positions currency: 'ETH'
    assert_empty positions
  end
end

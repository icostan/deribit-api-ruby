require 'minitest_helper'

class Deribit::ClientTest < Minitest::Test
  def setup
    @client = Deribit::Client.new
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
end

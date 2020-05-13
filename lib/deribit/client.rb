# frozen_string_literal: true

module Deribit
  TESTNET_HOST = 'test.deribit.com'.freeze
  MAINNET_HOST = 'www.deribit.com'.freeze

  # Deribit API 2.0 client implementation
  # @author Iulian Costan (deribit-api@iuliancostan.com)
  class Client
    attr_reader :http, :websocket

    # Create new instance
    # @param key [String] Deribit Access Key
    # @param secret [String] Deribit Secret Key
    # @param testnet [Boolean] set to true for testing
    # @param debug [Boolean] set to true for debug output
    # @return [Deribit::Client] the instance of client
    def initialize(key: nil, secret: nil, testnet: false, debug: false)
      host = testnet ? TESTNET_HOST : MAINNET_HOST
      @http = Deribit::Http.new host, key: key, secret: secret, debug: debug
      @websocket = Deribit::Websocket.new host, key: key, secret: secret
    end

    # Retrieves available trading instruments.
    # @param options [Hash]
    # @option options [String] :currency the currency to get instruments for
    # @option options [String] :kind instrument kind, if not provided instruments of all kinds are considered
    # @option options [Integer] :expired set to true to show expired instruments instead of active ones.
    # @return [Array] the list of instruments
    # @see https://docs.deribit.com/#public-get_instruments
    def instruments(options = { currency: 'BTC' })
      raise ArgumentError, 'currency is required' unless options[:currency]

      http.get '/public/get_instruments', options
    end

    # Retrieves all cryptocurrencies supported by the API.
    # @return [Array] the list of cryptocurrencies
    # @see https://docs.deribit.com/#public-get_currencies
    def currencies
      http.get '/public/get_currencies'
    end

    # Retrieves the current index price for the BTC-USD instruments.
    # @param options [Hash]
    # @option options [String] :currency the currency to get instruments for
    # @return [Hashie::Mash] index price for BTC-USD instrument
    # @see https://docs.deribit.com/#public-get_index
    def index(options = { currency: 'BTC' })
      unless options[:currency]
        raise ArgumentError, 'currency argument is required'
      end

      http.get '/public/get_index', options
    end

    # Notifies about changes to the order book for a certain instrument.
    # @param instrument_name [String] The instrument name
    # @param options [Hash]
    # @option options [String] :instrument_name (BTC-PERPETUAL) Instrument to return open orders for
    # @option options [Integer] :group (5) Group prices (by rounding): none, 5, 10
    # @option options [Integer] :depth (10) the depth of the order book
    # @option options [String] :interval (raw) Frequency of notifications: raw, 100ms
    # @return [Hashie::Mash] the order book
    # @yield [Hashie::Mash] the order book
    # @see https://docs.deribit.com/#book-instrument_name-group-depth-interval
    # @see https://docs.deribit.com/#book-instrument_name-interval
    def book(options = { instrument_name: 'BTC-PERPETUAL' }, &blk)
      unless options[:instrument_name]
        raise ArgumentError, 'instrument_name argument is required'
      end

      if block_given?
        channel = Naming.book_channel options
        websocket.subscribe channel, params: {}, &blk
      else
        http.get '/public/get_order_book', options
      end
    end

    # Retrieve the latest trades that have occurred for instruments in a specific currency symbol/for a specific instrument and optionally within given time range.
    # @!macro deribit.filters
    #   @param filters [Hash] filters to apply
    #   @option filters [String] :instrument_name (BTC-PERPETUAL) Instrument name
    #   @option filters [String] :currency (BTC, ETH) The currency symbol
    #   @option filters [String] :kind (future, option) Instrument kind, if not provided instruments of all kinds are considered
    #   @option filters [Integer] :count (10) Number of requested items
    #   @option filters [Integer] :start_id The ID of the first trade to be returned
    #   @option filters [Integer] :end_id The ID of the last trade to be returned
    #   @option filters [Integer] :start_seq The trade sequence of the first trade to be returned
    #   @option filters [Integer] :end_seq The trade sequence of the last trade to be returned
    #   @option filters [Integer] :start_timestamp The timestamp (in ms) of the first trade to be returned
    #   @option filters [Integer] :end_timestamp The timestamp (in ms) of the last trade to be returned
    #   @option filters [Boolean] :include_old (false) Include trades older than a few recent days
    #   @option filters [Boolean] :sorting (none) Direction of results sorting
    #   @option filters [String] :interval (raw) Frequency of notifications.
    # @return [Array] the list of trades
    # @yield [Hashie::Mash] new trade
    # @see https://docs.deribit.com/#public-get_last_trades_by_currency
    # @see https://docs.deribit.com/#public-get_last_trades_by_currency_and_time
    # @see https://docs.deribit.com/#public-get_last_trades_by_instrument
    # @see https://docs.deribit.com/#public-get_last_trades_by_instrument_and_time
    # @see https://docs.deribit.com/#private-get_user_trades_by_currency
    # @see https://docs.deribit.com/#private-get_user_trades_by_currency_and_time
    # @see https://docs.deribit.com/#private-get_user_trades_by_instrument
    # @see https://docs.deribit.com/#private-get_user_trades_by_instrument_and_time
    # @see https://docs.deribit.com/#trades-instrument_name-interval
    # @see https://docs.deribit.com/#trades-kind-currency-interval
    # @see https://docs.deribit.com/#user-trades-instrument_name-interval
    # @see https://docs.deribit.com/#user-trades-kind-currency-interval
    def trades(filters, &blk)
      instrument_name = filters[:instrument_name]
      currency = filters[:currency]
      unless instrument_name || currency
        raise ArgumentError, 'either :instrument_name or :currency args is required'
      end

      if block_given?
        channel = Naming.trades_channel filters
        websocket.subscribe channel, params: {}, &blk
      else
        uri = Naming.trades_uri filters
        response = http.get uri, filters
        response.trades
      end
    end

    # Retrieves announcements from last 30 days.
    # @return [Array] the list of announcements
    # @yield [Hashie::Mash] the announcement
    # @see https://docs.deribit.com/#public-get_announcements
    # @see https://docs.deribit.com/#announcements
    def announcements(&blk)
      if block_given?
        websocket.subscribe 'announcements', &blk
      else
        http.get '/public/get_announcements'
      end
    end

    # Retrieves settlement, delivery and bankruptcy events that have occurred.
    # @param filters [Hash] the filters
    # @option filters [String] :instrument_name The instrument name,
    # @option filters [String] :currency The currency of settlements
    # @option filters [String] :type settlement type: settlement delivery bankruptcy
    # @option filters [Integer] :count (20) Number of requested items, default
    # @option filters [String] :continuation Continuation token for pagination
    # @return [Hashie::Mash] the settlements
    # @yield [Hashie::Mash] the settlements
    # @see https://docs.deribit.com/#public-get_last_settlements_by_instrument
    # @see https://docs.deribit.com/#public-get_last_settlements_by_currency
    def settlements(filters = { instrument_name: 'BTC-PERPETUAL' })
      instrument_name = filters[:instrument_name]
      currency = filters[:currency]
      unless instrument_name || currency
        raise ArgumentError, 'either :instrument_name or :currency arg is required'
      end

      if block_given?
        raise Deribit::NotImplementedError, 'not implemented'
      else
        http.get '/public/get_last_settlements_by_instrument', filters
      end
    end

    # Retrieves user account summary.
    # @param currency [String] Currency summary
    # @param ext [Boolean] Requests additional fields
    # @return [Hashie::Mash] the account details
    # @yield [Hashie::Mash] the account details
    # @see https://docs.deribit.com/#private-get_account_summary
    def account(currency: 'BTC', ext: false)
      if block_given?
        raise Deribit::NotImplementedError, 'not implemented'
      else
        http.get '/private/get_account_summary', currency: currency
      end
    end

    # Places a buy order for an instrument.
    # @param instrument_name [String] Name of the instrument to buy
    # @param amount [Integer] The number of contracts to buy
    # @!macro deribit.buy_sell_options
    #   @param options [Hash] more options for the order
    #   @option options [String] :type (limit) The order type, possible types: "limit", "stop_limit", "market", "stop_market"
    #   @option options [String] :label user defined label for the order (maximum 32 characters)
    #   @option options [Float] :price The order price (Only valid for limit and stop_limit orders)
    #   @option options [String] :time_in_force (good_til_cancelled) Specifies how long the order remains in effect, possible values "good_til_cancelled", "fill_or_kill", "immediate_or_cancel"
    #   @option options [Integer] :max_show Maximum quantity within an order to be shown to other customers, 0 for invisible order.
    #   @option options [String] :post_only (true)  If true, the order is considered post-only. If the new price would cause the order to be filled immediately (as taker), the price will be changed to be just below the bid.
    #   @option options [String] :reject_post_only (false) If order is considered post-only and this field is set to true than order is put to order book unmodified or request is rejected.
    #   @option options [String] :reduce_only  If true, the order is considered reduce-only which is intended to only reduce a current position

    #   @option options [Float] :stop_price price required for stop limit orders (Only valid for stop orders)
    #   @option options [String] :trigger Defines trigger type: index_price mark_price last_price, required for "stop_limit" order type
    #   @option options [String] :advanced Advanced option order type, can be "implv", "usd". (Only valid for options)
    # @return [Hashie::Mash] the details of new order
    # @see https://docs.deribit.com/#private-buy
    def buy(instrument_name, amount, options = {})
      params = options.merge instrument_name: instrument_name, amount: amount
      http.get 'private/buy', params
    end

    # Places a sell order for an instrument.
    # @param instrument_name [String] Name of the instrument to sell
    # @param amount [Integer] The number of contracts to buy
    # @!macro deribit.buy_sell_options
    # @return [Hashie::Mash] the details of new order
    # @see https://docs.deribit.com/#private-sell
    def sell(instrument_name, amount, options = {})
      params = options.merge instrument_name: instrument_name, amount: amount
      http.get '/private/sell', params
    end

    # Close a position
    # @param instrument_name [String] Name of the instrument to sell
    # @param type [String]
    # @param options [Hash] the options
    # @option options [String] :type The order type: limit or market
    # @option options [String] :price Price for limit close
    # @return [Hashie::Mash] the details of closed position
    # @see https://docs.deribit.com/#private-sell
    def close(instrument_name, options = { type: :market })
      params = options.merge instrument_name: instrument_name, type: options[:type]
      http.get '/private/close_position', params
    end

    # Changes price and/or quantity of the own order.
    # @param order_id [String] ID of the order to edit
    # @param amount [Integer] The new order quantity
    # @param price [Float] The new order price
    # @param options [Hash] extra options
    # @option options [Boolean] :post_only If true, the edited order is considered post-only. If the new price would cause the order to be filled immediately (as taker), the price will be changed to be just below the bid (for buy orders) or just above the ask (for sell orders).
    # @option options [Boolean] :reduce_only If true, the order is considered reduce-only which is intended to only reduce a current position
    # @option options [Boolean] :reject_post_only If order is considered post-only and this field is set to true than order is put to order book unmodified or request is rejected.
    # @option options [String] :advanced Advanced option order type. If you have posted an advanced option order, it is necessary to re-supply this parameter when editing it (Only for options)
    # @option options [Float] :stop_price Stop price, required for stop limit orders (Only for stop orders)
    # @return [Hashie::Mash] the edited order
    # @see https://docs.deribit.com/#private-edit
    def edit(order_id, amount, price, options = {})
      params = options.merge order_id: order_id, amount: amount, price: price
      http.get '/private/edit', params
    end

    # Cancels an order, specified by order id.
    # @param order_id [String] The order id of the order to be cancelled
    # @return [Hashie::Mash] details of the cancelled order
    # @see https://docs.deribit.com/#private-cancel
    def cancel(order_id)
      http.get '/private/cancel', order_id: order_id
    end

    # Cancels all orders, optionally filtered by instrument or instrument type.
    # @param options [Hash] extra options
    # @option options [String] :instrument_name The name of the instrument for which to cancel all orders
    # @option options [String] :currency The currency symbol
    # @option options [String] :type Which type of orders to cancel. Valid values are "all", "futures", "options"
    # @option options [String] :kind Instrument kind, if not provided instruments of all kinds are considered
    # @return [Boolean] success or not
    # @see https://docs.deribit.com/#private-cancel_all
    # @see https://docs.deribit.com/#private-cancel_all_by_currency
    # @see https://docs.deribit.com/#private-cancel_all_by_instrument
    def cancel_all(options = {})
      uri = Naming.cancel_uri options
      http.get uri, options
    end

    # Best bid/ask price and size.
    # @param options [Hash]
    # @option options [String] :instrument_name (BTC-PERPETUAL) Instrument to return open orders for
    # @see https://docs.deribit.com/#quote-instrument_name
    def quote(options = { instrument_name: 'BTC-PERPETUAL' }, &blk)
      unless block_given?
        raise 'block is missing, HTTP-RPC not supported for this endpoint'
      end

      channel = Naming.channel_for_instrument 'quote', options
      websocket.subscribe channel, params: options, &blk
    end

    # Key information about the instrument
    # @param options [Hash]
    # @option options [String] :instrument_name (BTC-PERPETUAL) Instrument to return open orders for
    # @option options [String] :interval (raw) Frequency of notifications: raw, 100ms
    # @see https://docs.deribit.com/#ticker-instrument_name-interval
    def ticker(options = { instrument_name: 'BTC-PERPETUAL' }, &blk)
      if block_given?
        channel = Naming.channel 'ticker', options
        websocket.subscribe channel, params: options, &blk
      else
        http.get '/public/ticker', options
      end
    end

    # Retrieves open orders.
    # @param options [Hash]
    # @option options [String] :instrument_name Instrument to return open orders for
    # @option options [String] :currency The currency symbol, BTC, ETH, any
    # @option options [string] :kind (any) Instrument kind, future, option or any
    # @option options [string] :type (all) Order type: all, limit, stop_all, stop_limit, stop_market
    # @option options [String] :interval (raw) Frequency of notifications: raw, 100ms
    # @return [Array] the list of open orders
    # @yield [Hashie::Mash] the order
    # @see https://docs.deribit.com/#private-get_open_orders_by_currency
    # @see https://docs.deribit.com/#private-get_open_orders_by_instrument
    def orders(options, &blk)
      raise ArgumentError, 'either :instrument_name or :currency is required' unless options[:instrument_name] || options[:currency]

      if block_given?
        channel = Naming.channel 'user.orders', options
        websocket.subscribe channel, params: options, &blk
      else
        uri = Naming.orders_uri options
        http.get uri, options
      end
    end

    # Retrieves current positions.
    # @param options [Hash]
    # @option options [String] :currency (any) The currency symbol, BTC, ETH
    # @option options [string] :kind  (any) Instrument kind, future, option
    # @return [Array] the list of positions
    # @see https://docs.deribit.com/#private-get_positions
    def positions(options = { currency: 'BTC' })
      http.get '/private/get_positions', options
    end
  end
end

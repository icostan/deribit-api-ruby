module Deribit
  # @author Iulian Costan
  class Client
    # URL for testnet
    TESTNET_URL = 'test.deribit.com'
    # URL for mainnet
    MAINNET_URL = 'www.deribit.com'

    attr_reader :websocket

    # Create new instance
    # @param key [String] Deribit Access Key
    # @param secret [String] Deribit Secret Key
    # @param testnet [Boolean] set to true for testing
    # @param debug [Boolean] set to true for debug output
    # @return [Deribit::Client] the instance of client
    def initialize(key: nil, secret: nil, testnet: false, debug: false)
      host = testnet ? TESTNET_URL : MAINNET_URL
      @connection = Faraday::Connection.new(url: 'https://' + host) do |f|
        f.request :json
        f.response :mashify
        f.response :json
        f.use Deribit::Authentication, key, secret
        f.response :logger if debug
        f.adapter Faraday.default_adapter
      end
      @websocket = Deribit::Websocket.new host, key: key, secret: secret
    end

    # Retrieves the current time (in ms).
    # @return [Integer] current time in milliseconds
    # @yield [Integer] current time in milliseconds
    # @see https://docs.deribit.com/rpc-endpoints.html#time
    def time(&blk)
      if block_given?
        websocket.subscribe :time, &blk
      else
        get :time
      end
    end

    # Signals the Websocket connection to send and request heartbeats.
    # @param interval [Integer] The heartbeat interval
    # @yield [String] 'ok' on success, error message otherwise
    # @see https://docs.deribit.com/rpc-endpoints.html#setheartbeat
    def enable_heartbeat(interval = 60, &blk)
      raise 'This API endpoint cannot be used over HTTP.' unless block_given?

      websocket.subscribe :setheartbeat, params: { interval: interval }, &blk
    end

    # Signals the Websocket connection to not send or request heartbeats.
    # @yield [String] 'ok' on success, error message otherwise
    # @see https://docs.deribit.com/rpc-endpoints.html#cancelheartbeat
    def cancel_heartbeat(&blk)
      raise 'This API endpoint cannot be used over HTTP.' unless block_given?

      websocket.subscribe :cancelheartbeat, &blk
    end

    # Tests the connection to the API server, and returns its version.
    # @param exception [any] Provide this parameter force an error message.
    # @return [Hashie::Mash] test data
    # @yield [Hashie::Mash] test data
    # @see https://docs.deribit.com/rpc-endpoints.html#test
    def test(exception: false, &blk)
      params = { exception: exception }
      if block_given?
        websocket.subscribe :test, params: params, &blk
      else
        get :test, params: params, raw_body: true
      end
    end

    # This API endpoint always responds with "pong".
    # @return [String] pong
    # @yield [String] pong
    # @see https://docs.deribit.com/rpc-endpoints.html#ping
    def ping(&blk)
      if block_given?
        websocket.subscribe :ping, &blk
      else
        get :ping
      end
    end

    # Retrieves available trading instruments.
    # @param expired [Boolean] Set to true to show expired instruments instead of active ones.
    # @return [Array] the list of instruments
    # @yield [Hashie::Mash] the instrument
    # @see https://docs.deribit.com/rpc-endpoints.html#getinstruments
    def instruments(expired: false, &blk)
      params = { expired: expired }
      if block_given?
        websocket.subscribe :getinstruments, params: params, &blk
      else
        get :getinstruments, params: params
      end
    end

    # Retrieves all cryptocurrencies supported by the API.
    # @return [Array] the list of cryptocurrencies
    # @yield [Hashie:Hash] the currency
    # @see https://docs.deribit.com/rpc-endpoints.html#getcurrencies
    def currencies(&blk)
      if block_given?
        websocket.subscribe :getcurrencies, &blk
      else
        get :getcurrencies
      end
    end

    # Retrieves the current index price for the BTC-USD instruments.
    # @param currency [String] the currency to get index for
    # @return [Hashie::Mash] index price for BTC-USD instrument
    # @yield [Hashie::Mash] index price for BTC-USD instrument
    # @see https://docs.deribit.com/rpc-endpoints.html#index
    def index(currency = 'BTC', &blk)
      params = { currency: currency }
      if block_given?
        websocket.subscribe :index, params: params, &blk
      else
        get :index, params: params
      end
    end

    # Retrieves the order book, along with other market values for a given instrument.
    # @param instrument [String] The instrument name for which to retrieve the order book, (see #instruments)  to obtain instrument names.
    # @param depth [Integer] the depth of the order book
    # @return [Hashie::Mash] the order book
    # @yield [Hashie::Mash] the order book
    # @see https://docs.deribit.com/rpc-endpoints.html#getorderbook
    def orderbook(instrument, depth: 10, &blk)
      raise ArgumentError, 'instrument param is required' unless instrument

      params = { instrument: instrument, depth: depth }
      if block_given?
        websocket.subscribe :getorderbook, params: params, &blk
      else
        get :getorderbook, params: params
      end
    end

    # Retrieve the latest trades that have occurred for a specific instrument.
    # @param instrument [String] Either the name of the instrument, or "all" for all active instruments, "futures" for all active futures, or "options" for all active options.
    # @!macro deribit.filters
    #   @param filters [Hash] extra filters to apply
    #   @option filters [Integer] :count (10) The number of trades returned (clamped to max 1000)
    #   @option filters [Integer] :startId The ID of the first trade to be returned
    #   @option filters [Integer] :endId The ID of the last trade to be returned
    #   @option filters [Integer] :startSeq The trade sequence of the first trade to be returned
    #   @option filters [Integer] :endSeq The trade sequence of the last trade to be returned
    #   @option filters [Integer] :startTimestamp The timestamp (in ms) of the first trade to be returned
    #   @option filters [Integer] :endTimestamp The timestamp (in ms) of the last trade to be returned
    #   @option filters [Boolean] :includeOld (false) to get archived trades for expired instruments when true (added from performance considerations)
    # @return [Array] the list of trades
    # @yield [Hashie::Mash] new trade
    # @see https://docs.deribit.com/rpc-endpoints.html#getlasttrades
    def trades(instrument = :all, filters = {}, &blk)
      raise ArgumentError, 'instrument param is required' unless instrument

      params = filters.merge(instrument: instrument)
      if block_given?
        websocket.subscribe :getlasttrades, params: params, &blk
      else
        get :getlasttrades, params: params
      end
    end

    # Retrieves the summary information such as open interest, 24h volume, etc. for a specific instrument.
    # @param instrument [String] Either the name of the instrument, or 'all' for all active instruments, 'futures' for all active futures, or 'options' for all active options.
    # @return [Array, Hashie::Mash] the summary as array or hash based on instrument param
    # @yield [Hashie::Mash] the summary
    # @see https://docs.deribit.com/rpc-endpoints.html#getsummary
    def summary(instrument = :all, &blk)
      raise ArgumentError, 'instrument argument is required' unless instrument

      params = { instrument: instrument }
      if block_given?
        websocket.subscribe :getsummary, params: params, &blk
      else
        get :getsummary, params: params
      end
    end

    # Retrieves aggregated 24h trade volumes for different instrument types.
    # @return [Hashie::Mash] the statistics
    # @yield [Hashie::Mash] the statistics
    # @see https://docs.deribit.com/rpc-endpoints.html#stats
    def stats(&blk)
      if block_given?
        websocket.subscribe :stats, &blk
      else
        get :stats
      end
    end

    # Retrieves announcements from last 30 days.
    # @return [Array] the list of announcements
    # @yield [Hashie::Mash] the announcement
    # @see https://docs.deribit.com/rpc-endpoints.html#getannouncements
    def announcements(&blk)
      if block_given?
        websocket.subscribe :getannouncements, &blk
      else
        get :getannouncements
      end
    end

    # Retrieves settlement, delivery and bankruptcy events that have occurred.
    # @param filters [Hash] the filters
    # @option filters [String] :instrument The instrument name, or "all" to retrieve settlements for all instruments
    # @option filters [Integer] :count (10) The number of entries to be returned. This is clamped to max 1000
    # @option filters [String] :type The type of settlements to return. Possible values "settlement", "delivery", "bankruptcy"
    # @option filters [Integer] :startTstamp The latest timestamp to return result for
    # @option filters [String] :continuation Continuation token for pagination. Each response contains a token to be used for continuation
    # @return [Hashie::Mash] the settlements
    # @yield [Hashie::Mash] the settlements
    # @see https://docs.deribit.com/rpc-endpoints.html#getlastsettlements
    def settlements(filters = {}, &blk)
      if block_given?
        websocket.subscribe :getlastsettlements, params: filters, &blk
      else
        get :getlastsettlements, params: filters
      end
    end

    # Retrieves user account summary.
    # @param ext [Boolean] Requests additional fields
    # @return [Hashie::Mash] the account details
    # @yield [Hashie::Mash] the account details
    # @see https://docs.deribit.com/rpc-endpoints.html#account
    def account(ext: false, &blk)
      if block_given?
        websocket.subscribe :account, params: { auth: true }, &blk
      else
        get :account, auth: true
      end
    end

    # Places a buy order for an instrument.
    # @param instrument [String] Name of the instrument to buy
    # @param quantity [Integer] The number of contracts to buy
    # @!macro deribit.options
    #   @param options [Hash] more options for the order
    #   @option options [String] :type (limit) The order type, possible types: "limit", "stop_limit", "market", "stop_market"
    #   @option options [Float] :price The order price (Only valid for limit and stop_limit orders)
    #   @option options [String] :label user defined label for the order (maximum 32 characters)
    #   @option options [String] :time_in_force (good_til_cancelled) Specifies how long the order remains in effect, possible values "good_til_cancelled", "fill_or_kill", "immediate_or_cancel"
    #   @option options [Integer] :max_show Maximum quantity within an order to be shown to other customers, 0 for invisible order.
    #   @option options [String] :post_only (true)  If true, the order is considered post-only. If the new price would cause the order to be filled immediately (as taker), the price will be changed to be just below the bid.
    #   @option options [Float] :stopPx Stop price required for stop limit orders (Only valid for stop orders)
    #   @option options [String] :execInst (index_price) Defines trigger type, required for "stop_limit" order type, possible values "index_price", "mark_price" (Only valid for stop orders)
    #   @option options [String] :adv Advanced option order type, can be "implv", "usd". (Only valid for options)
    # @return [Hashie::Mash] the details of new order
    # @yield [Hashie::Mash] the details of new order
    # @see https://docs.deribit.com/rpc-endpoints.html#buy
    def buy(instrument, quantity, options = {}, &blk)
      params = { instrument: instrument, quantity: quantity, price: options[:price] }
      if block_given?
        websocket.subscribe :buy, params: params.merge(auth: true), &blk
      else
        post :buy, params
      end
    end

    # Places a sell order for an instrument.
    # @param instrument [String] Name of the instrument to sell
    # @param quantity [Integer] The number of contracts to sell
    # @!macro deribit.options
    # @return [Hashie::Mash] the details of new order
    # @yield [Hashie::Mash] the details of new order
    # @see https://docs.deribit.com/rpc-endpoints.html#sell
    def sell(instrument, quantity, options = {}, &blk)
      params = options.merge instrument: instrument, quantity: quantity, auth: true
      if block_given?
        websocket.subscribe :sell, params: params, &blk
      else
        post :sell, params
      end
    end

    # Changes price and/or quantity of the own order.
    # @param order_id [String] ID of the order to edit
    # @param quantity [Integer] The new order quantity
    # @param price [Float] The new order price
    # @param options [Hash] extra options
    # @option options [Boolean] :post_only If true, the edited order is considered post-only. If the new price would cause the order to be filled immediately (as taker), the price will be changed to be just below the bid (for buy orders) or just above the ask (for sell orders).
    # @option options [String] :adv The new advanced order type (only valid for option orders)
    # @option options [Float] :stopPx The new stop price (only valid for stop limit orders)
    # @return [Hashie::Mash] the edited order
    # @yield [Hashie::Mash] the edited order
    # @see https://docs.deribit.com/rpc-endpoints.html#edit
    def edit(order_id, quantity, price, options = {}, &blk)
      params = options.merge orderId: order_id, quantity: quantity, price: price, auth: true
      if block_given?
        websocket.subscribe :edit, params: params, &blk
      else
        post :edit, params
      end
    end

    # Cancels an order, specified by order id.
    # @param order_id [String] The order id of the order to be cancelled
    # @return [Hashie::Mash] details of the cancelled order
    # @yield [Hashie::Mash] details of the cancelled order
    # @see https://docs.deribit.com/rpc-endpoints.html#cancel
    def cancel(order_id, &blk)
      params = { orderId: order_id, auth: true }
      if block_given?
        websocket.subscribe :cancel, params: params, &blk
      else
        post :cancel, params
      end
    end

    # Cancels all orders, optionally filtered by instrument or instrument type.
    # @param type [all futures options] Which type of orders to cancel. Valid values are "all", "futures", "options"
    # @param options [Hash] extra options
    # @option options [String] :instrument The name of the instrument for which to cancel all orders
    # @return [Boolean] success or not
    # @yield [Boolean] success or not
    # @see https://docs.deribit.com/rpc-endpoints.html#cancelall
    def cancelall(type = :all, options = {}, &blk)
      params = options.merge type: type, auth: true
      if block_given?
        websocket.subscribe :cancelall, params: params, &blk
      else
        post :cancelall, params
      end
    end

    # Retrieves open orders.
    # @param options [Hash]
    # @option options [String] :instrument Instrument to return open orders for
    # @option options [string] ;orderId order ID
    # @option options [String] :type Order types to return. Valid values include "limit", "stop_limit", "any"
    # @return [Array] the list of open orders
    # @yield [Hashie::Mash] the order
    # @see https://docs.deribit.com/rpc-endpoints.html#getopenorders
    def orders(options = {}, &blk)
      if block_given?
        websocket.subscribe :getopenorders, params: options.merge(auth: true), &blk
      else
        get :getopenorders, auth: true, params: options
      end
    end

    # Retrieves current positions.
    # @return [Array] the list of positions
    # @yield [Hashie::Mash] the position
    # @see https://docs.deribit.com/rpc-endpoints.html#positions
    def positions(&blk)
      params = { auth: true }
      if block_given?
        websocket.subscribe :positions, params: params, &blk
      else
        get :positions, params
      end
    end

    # Retrieves history of orders that have been partially or fully filled.
    # @param options [Hash]
    # @option options [String] :instrument Instrument to return open orders for
    # @option options [String] :count The number of items to be returned.
    # @option options [string] :offset The offset for pagination
    # @return [Array] the list of history orders
    # @yield [Hashie::Mash] the order
    # @see https://docs.deribit.com/rpc-endpoints.html#orderhistory
    def orders_history(options = {}, &blk)
      if block_given?
        websocket.subscribe :orderhistory, params: options.merge(auth: true), &blk
      else
        get :orderhistory, auth: true, params: options
      end
    end

    # Retrieve order details state by order id.
    # @param order_id [String] the ID of the order to be retrieved
    # @return [Hashie::Mash] the details of the order
    # @yield [Hashie::Mash] the details of the order
    # @see https://docs.deribit.com/rpc-endpoints.html#orderstate
    def order(order_id, &blk)
      params = { orderId: order_id, auth: true }
      if block_given?
        websocket.subscribe :orderstate, params: params, &blk
      else
        get :orderstate, auth: true, params: params
      end
    end

    # Retrieve the trade history of the account
    # @param instrument [String] Either the name of the instrument, or "all" for instruments, "futures" for all futures, or "options" for all options.
    # @!macro deribit.filters
    # @return [Array] the list of trades
    # @yield [Hashie::Mash] the trade
    # @see https://docs.deribit.com/rpc-endpoints.html?q=#tradehistory
    def trades_history(instrument = :all, filters = {}, &blk)
      params = filters.merge(instrument: instrument, auth: true)
      if block_given?
        websocket.subscribe :tradehistory, params: params, &blk
      else
        get :tradehistory, auth: true, params: params
      end
    end

    # Retrieves announcements that have not been marked read by the current user.
    # @return [Array] the list of new announcements
    # @yield [Hashie::Mash] the announcement
    def new_announcements(&blk)
      if block_given?
        websocket.subscribe :newannouncements, params: { auth: true }, &blk
      else
        get :newannouncements, auth: true
      end
    end

    # Logs out the websocket connection.
    # @yield [Boolean] success or not
    # @see https://docs.deribit.com/rpc-endpoints.html#logout
    def logout(&blk)
      raise 'This API endpoint cannot be used over HTTP.' unless block_given?

      websocket.subscribe :logout, params: {}, &blk
    end

    # Enables or disables "COD" (cancel on disconnect) for the current connection.
    # @param state [String] Whether COD is to be enabled for this connection. "enabled" or "disabled"
    # @yield [Boolean] success or not
    # @see https://docs.deribit.com/rpc-endpoints.html#cancelondisconnect
    def cancelondisconnect(state, &blk)
      raise 'This API endpoint cannot be used over HTTP.' unless block_given?

      websocket.subscribe :cancelondisconnect, params: { state: state, auth: true }, &blk
    end

    # Retrieves the language to be used for emails.
    # @return [String] the language name (e.g. "en", "ko", "zh")
    # @yield [String] the language name (e.g. "en", "ko", "zh")
    def getemaillang(&blk)
      if block_given?
        websocket.subscribe :getemaillang, params: { auth: true }, &blk
      else
        get :getemaillang, auth: true
      end
    end

    # Changes the language to be used for emails.
    # @param lang [String] the abbreviated language name. Valid values include "en", "ko", "zh"
    # @return [Boolean] success or not
    # @yield [Boolean] success or not
    def setemaillang(lang, &blk)
      if block_given?
        websocket.subscribe :setemaillang, params: { lang: lang, auth: true }, &blk
      else
        post :setemaillang, lang: lang
      end
    end

    # Marks an announcement as read, so it will not be shown in newannouncements
    # @param announcement_id [String]  the ID of the announcement
    # @return [String] ok
    # @yield [String] ok
    def setannouncementasread(announcement_id, &blk)
      if block_given?
        websocket.subscribe :setannouncementasread, params: { announcementid: announcement_id, auth: true }, &blk
      else
        post :setannouncementasread, announcementid: announcement_id
      end
    end

    # Retrieves settlement, delivery and bankruptcy events that have affected your account.
    # @param filters [Hash] the filters
    # @option filters [String] :instrument The instrument name, or "all" to retrieve settlements for all instruments
    # @option filters [Integer] :count (10) The number of entries to be returned. This is clamped to max 1000
    # @option filters [String] :type The type of settlements to return. Possible values "settlement", "delivery", "bankruptcy"
    # @option filters [Integer] :startTstamp The latest timestamp to return result for
    # @option filters [String] :continuation Continuation token for pagination. Each response contains a token to be used for continuation
    # @return [Hashie::Mash] the settlements
    # @yield [Hashie::Mash] the settlement
    # @see https://docs.deribit.com/rpc-endpoints.html#settlementhistory
    def settlements_history(filters = {}, &blk)
      if block_given?
        websocket.subscribe :settlementhistory, params: filters.merge(auth: true), &blk
      else
        get :settlementhistory, auth: true, params: filters
      end
    end

    private

    def get(action, params: {}, raw_body: false, auth: false)
      response = @connection.get path(action, auth), params
      # TODO: move to middleware
      raise response.message unless response.success?
      raise response.body.message unless response.body.success
      body = response.body
      raw_body ? body : body.result
    end

    def post(action, params)
      response = @connection.post path(action, true), params
      raise response.message unless response.success?
      raise response.body.message unless response.body.success

      response.body.result || response.body.success?
    end

    def path(action, auth = false)
      access = auth ? 'private' : 'public'
      "/api/v1/#{access}/#{action}"
    end
  end
end

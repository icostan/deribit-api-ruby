module Deribit
  # @author Iulian Costan
  class Client
    # URL for testnet
    TESTNET_URL = 'https://test.deribit.com'
    # URL for mainnet
    MAINNET_URL = 'https://www.deribit.com'

    # Create new instance
    # @param testnet [Boolean] set to true for testing
    # @param debug [Boolean] set to true for debug output
    # @return [Deribit::Client] the instance of client
    def initialize(testnet: false, debug: false)
      url = testnet ? TESTNET_URL : MAINNET_URL
      @connection = Faraday::Connection.new(url: url) do |f|
        f.request :json
        f.response :mashify
        f.response :json
        f.response :logger if debug
        f.adapter Faraday.default_adapter
      end
    end

    # Retrieves the current time (in ms).
    # @return [Integer] current time in milliseconds
    # @see https://docs.deribit.com/rpc-endpoints.html#time
    def time
      execute :time
    end

    # Tests the connection to the API server, and returns its version.
    # @param exception [any] Provide this parameter force an error message.
    # @return [Hashie::Mash] test data
    # @see https://docs.deribit.com/rpc-endpoints.html#test
    def test(exception: false)
      execute :test, params: { exception: exception }, raw_body: true
    end

    # This API endpoint always responds with "pong".
    # @return [Hashie::Mash] ping
    # @see https://docs.deribit.com/rpc-endpoints.html#ping
    def ping
      execute :ping
    end

    # Retrieves available trading instruments.
    # @param expired [Boolean] Set to true to show expired instruments instead of active ones.
    # @return [Array] the list of instruments
    # @see https://docs.deribit.com/rpc-endpoints.html#getinstruments
    def instruments(expired: false)
      execute :getinstruments, params: { expired: expired }
    end

    # Retrieves all cryptocurrencies supported by the API.
    # @return [Array] the list of cryptocurrencies
    # @see https://docs.deribit.com/rpc-endpoints.html#getcurrencies
    def currencies
      execute :getcurrencies
    end

    # Retrieves the current index price for the BTC-USD instruments.
    # @return [Hashie::Mash] index price for BTC-USD instrument
    # @see https://docs.deribit.com/rpc-endpoints.html#index
    def index
      execute :index
    end

    # Retrieves the order book, along with other market values for a given instrument.
    # @param instrument [String] The instrument name for which to retrieve the order book, (see #instruments)  to obtain instrument names.
    # @param depth [Integer] the depth of the order book
    # @return [Hashie::Mash] the order book
    # @see https://docs.deribit.com/rpc-endpoints.html#getorderbook
    def orderbook(instrument, depth: 10)
      raise ArgumentError, 'instrument param is required' unless instrument

      execute :getorderbook, params: { instrument: instrument, depth: depth }
    end

    # Retrieve the latest trades that have occurred for a specific instrument.
    # @param instrument [String] Either the name of the instrument, or "all" for all active instruments, "futures" for all active futures, or "options" for all active options.
    # @param filters [Hash] the filters
    # @option filters [Integer] :count (10) The number of trades returned (clamped to max 1000)
    # @option filters [Integer] :startId The ID of the first trade to be returned
    # @option filters [Integer] :endId The ID of the last trade to be returned
    # @option filters [Integer] :startSeq The trade sequence of the first trade to be returned
    # @option filters [Integer] :endSeq The trade sequence of the last trade to be returned
    # @option filters [Integer] :startTimestamp The timestamp (in ms) of the first trade to be returned
    # @option filters [Integer] :endTimestamp The timestamp (in ms) of the last trade to be returned
    # @option filters [Boolean] :includeOld (false) to get archived trades for expired instruments when true (added from performance considerations)
    # @return [Array] the list of trades
    # @see https://docs.deribit.com/rpc-endpoints.html#getlasttrades
    def trades(instrument, filters = {})
      raise ArgumentError, 'instrument param is required' unless instrument

      execute :getlasttrades, params: filters.merge(instrument: instrument)
    end

    # Retrieves the summary information such as open interest, 24h volume, etc. for a specific instrument.
    # @param instrument [String] Either the name of the instrument, or 'all' for all active instruments, 'futures' for all active futures, or 'options' for all active options.
    # @return [Array, Hashie::Hash] the summary as array or hash based on instrument param
    # @see https://docs.deribit.com/rpc-endpoints.html#getsummary
    def summary(instrument)
      raise ArgumentError, 'instrument argument is required' unless instrument

      execute :getsummary, params: { instrument: instrument }
    end

    # Retrieves aggregated 24h trade volumes for different instrument types.
    # @return [Hashie::Mash] the statistics
    # @see https://docs.deribit.com/rpc-endpoints.html#stats
    def stats
      execute :stats
    end

    # Retrieves announcements from last 30 days.
    # @return [Array] the list of announcements
    # @see https://docs.deribit.com/rpc-endpoints.html#getannouncements
    def announcements
      execute :getannouncements
    end

    # Retrieves settlement, delivery and bankruptcy events that have occurred.
    # @param filters [Hash] the filters
    # @option filters [String] :instrument The instrument name, or "all" to retrieve settlements for all instruments
    # @option filters [Integer] :count (10) The number of entries to be returned. This is clamped to max 1000
    # @option filters [String] :type The type of settlements to return. Possible values "settlement", "delivery", "bankruptcy"
    # @option filters [Integer] :startTstamp The latest timestamp to return result for
    # @option filters [String] :continuation Continuation token for pagination. Each response contains a token to be used for continuation
    # @return [Hashie::Hash] the settlements
    # @see https://docs.deribit.com/rpc-endpoints.html#getlastsettlements
    def settlements(filters = {})
      execute :getlastsettlements, params: filters
    end

    private

    def execute(action, params: {}, raw_body: false)
      path = "/api/v1/public/#{action}"
      response = @connection.get path, params
      raise response.message unless response.success?
      raise response.body.message unless response.body.success

      body = response.body
      raw_body ? body : body.result
    end
  end
end

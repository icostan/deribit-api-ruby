# frozen_string_literal: true

module Deribit
  # Websocket API
  # @author Iulian Costan (deribit-api@iuliancostan.com)
  # @see https://docs.deribit.com/#subscriptions
  class Websocket
    attr_reader :host, :key, :secret, :access_token, :callbacks

    # Create new websocket instance
    # @param host [String] the underlying host to connect to
    # @param key [String] the api key
    # @param secret [String] the api secret
    # @return [Deribit::Websocket] new websocket instance
    def initialize(host, key: nil, secret: nil)
      @host = host
      @key = key
      @secret = secret
      @callbacks = {}
      @ws = nil
    end

    # Subscribe to a specific topic and optionally filter by symbol
    # @param topic [String] topic to subscribe to e.g. 'trade'
    # @param params [Hash] the arguments for subscription
    # @yield [Array] data payload
    def subscribe(topic, params: {}, &callback)
      raise 'block is required' unless block_given?

      # connect on demand
      @ws = connect unless connected?
      raise 'websocket is closed' unless @ws.open?

      # save callback handler
      @callbacks[topic.to_s] = callback

      # authorize if needed
      authorize if authorization_required?(topic)

      # subscription request
      payload = {
        jsonrpc: '2.0',
        method: 'public/subscribe',
        id: rand(9999),
        params: { channels: [topic] }
      }
      @ws.send payload.to_json.to_s
    end

    def authorized?
      !access_token.nil?
    end

    private

    def connected?
      !@ws.nil?
    end

    def authorization_required?(topic)
      topic.include? 'user'
    end

    def authorize
      timestamp = Time.now.utc.to_i * 1000
      nonce = rand(999_999).to_s
      signature = Deribit.signature timestamp, nonce, '', @secret
      payload = {
        jsonrpc: '2.0',
        method: 'public/auth',
        id: 'auth',
        params: {
          grant_type: :client_signature,
          client_id: @key,
          timestamp: timestamp,
          nonce: nonce,
          data: '',
          signature: signature
        }
      }
      @callbacks['auth'] = lambda do |result|
        @access_token = result['access_token']
      end
      @ws.send payload.to_json.to_s
    end

    def websocket_url
      "wss://#{host}/ws/api/v2"
    end

    def connect
      websocket = self
      ws = WebSocket::Client::Simple.connect websocket_url
      ws.on :open do |event|
        # puts [:open, event]
      end
      ws.on :error do |event|
        # puts [:error, event.inspect]
      end
      ws.on :close do |event|
        # puts [:close, event.reason]
        ws = nil
      end
      ws.on :message do |event|
        json = JSON.parse event.data
        if json['method'] == 'subscription'
          id = json['params']['channel']
          data = json['params']['data']
          callback = websocket.callbacks[id]
          data = [data] if data.is_a? Hash
          data.each do |datum|
            @result = callback.yield Hashie::Mash.new(datum)
          end
        else
          id = json['id']
          callback = websocket.callbacks[id]
          callback&.yield json['result']
        end
      end
      until ws.open? do sleep 1 end # wait for opening
      ws
    end
  end
end

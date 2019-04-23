module Deribit
  # Websocket API
  # @see https://docs.deribit.com/api-websocket.html
  class Websocket
    attr_reader :host, :key, :secret

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
    end

    # Subscribe to a specific topic and optionally filter by symbol
    # @param topic [String] topic to subscribe to e.g. 'trade'
    # @param params [Hash] the arguments for subscription
    # @yield [Array] data payload
    def subscribe(topic, params: {}, &callback)
      raise 'callback block is required' unless block_given?

      EM.run do
        connect

        # request id
        id = Time.now.to_i
        @callbacks[id] = callback

        # request action
        auth = params.delete :auth
        uri = auth ? 'private' : 'public'
        action = "/api/v1/#{uri}/#{topic}"

        payload = { id: id, action: action, arguments: params }
        payload[:sig] = signature id, action, params if auth

        @faye.send payload.to_json.to_s
      end
    end

    # Stop websocket listener
    def stop
      EM.stop_event_loop
    end

    private

    def signature(nonce, action, params)
      payload = {
        _: nonce,
        _ackey: @key,
        _acsec: @secret,
        _action: action
      }
      payload.merge! params
      # query = env['url'].query

      Deribit.signature @key, nonce, payload, nil
    end

    def websocket_url
      "wss://#{host}/ws/api/v1/"
    end

    def headers
      {}
    end

    def connect
      @result = nil
      @faye = Faye::WebSocket::Client.new websocket_url, [], headers: headers
      @faye.on :open do |_event|
        # puts [:open, event.data]
      end
      @faye.on :error do |event|
        raise event.message
      end
      @faye.on :close do |_event|
        # puts [:close, event.reason]
        @faye = nil
      end
      @faye.on :message do |event|
        json = JSON.parse event.data
        id = json['id']
        data = json['result'] || json['message']

        callback = @callbacks[id]
        # TODO: rewrite this part
        if callback && data
          data = [data] unless data.is_a? Array
          data.each do |payload|
            payload = Hashie::Mash.new payload if payload.is_a? Hash
            @result = callback.yield payload, @result
          end
        else
          puts "==> #{event.data}"
        end
      end
    end
  end
end

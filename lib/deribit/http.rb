module Deribit
  # HTTP API
  # @see https://docs.deribit.com/api-http.html
  class Http
    def initialize(host, key: nil, secret: nil, debug: false)
      url = 'https://' + host
      @connection = Faraday::Connection.new(url: url) do |f|
        f.request :json
        f.response :mashify
        f.response :json
        f.use Deribit::Authentication, key, secret
        f.response :logger if debug
        f.adapter Faraday.default_adapter
      end
    end

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

      # TODO: move to middleware
      raise response.message unless response.success?
      raise response.body.message unless response.body.success

      response.body.result || response.body.success?
    end

    private

    def path(action, auth = false)
      access = auth ? 'private' : 'public'
      "/api/v1/#{access}/#{action}"
    end
  end
end

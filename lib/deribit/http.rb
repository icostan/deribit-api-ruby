module Deribit
  # HTTP API
  # @author Iulian Costan (deribit-api@iuliancostan.com)
  # @see https://docs.deribit.com/api-http.html
  class Http
    def initialize(host, key: nil, secret: nil, debug: false)
      @connection = Faraday::Connection.new(url: http_url(host)) do |f|
        f.request :json
        f.use Deribit::Authentication, key, secret
        f.response :mashify
        f.response :json
        f.use Faraday::Response::RaiseError
        f.response :detailed_logger if debug
        f.adapter Faraday.default_adapter
      end
    end

    def get(uri, params = {})
      response = @connection.get path(uri), params

      # TODO: move to middleware
      # raise response.error unless response.error
      # raise response.body.message unless response.body.success

      body = response.body
      body.result
    end

    def post(uri, params)
      response = @connection.post path(uri), params

      # TODO: move to middleware
      raise response.message unless response.success?
      raise response.body.message unless response.body.success

      response.body.result || response.body.success?
    end

    private

    def path(uri)
      path = '/api/v2'
      path += '/' unless uri.start_with? '/'
      path += uri
      path
    end

    def http_url(host)
      'https://' + host
    end
  end
end

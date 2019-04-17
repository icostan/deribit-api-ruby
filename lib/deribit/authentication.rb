require 'base64'
require 'digest'

module Deribit
  # Deribit authentication implemented as Faraday middleware
  # @see https://docs.deribit.com/rpc-authentication.html
  class Authentication < Faraday::Middleware
    def initialize(app, key, secret)
      super(app)
      @key = key
      @secret = secret
    end

    def call(env)
      return @app.call(env) if @key.nil? || @secret.nil?

      nonce = Time.now.to_i
      env['request_headers']['X-Deribit-Sig'] = signature env, nonce

      @app.call env
    end

    def signature(env, nonce)
      params = {
        _: nonce,
        _ackey: @key,
        _acsec: @secret,
        _action: env['url'].path
      }
      params.merge! JSON.parse(env['body']) if env['body']
      query = env['url'].query

      Deribit.signature @key, nonce, params, query
    end
  end
end

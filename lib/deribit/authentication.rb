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
      # add POST params
      params.merge! JSON.parse(env['body']) if env['body']

      signature_string = params.map{ |key, value| "#{key}=#{value}" }.sort.join '&'
      # add GET query
      signature_string += "&#{env['url'].query}" if env['url'].query

      signature_digest = Digest::SHA256.digest signature_string
      signature_hash = Base64.encode64 signature_digest

      "#{@key}.#{nonce}.#{signature_hash.chomp}"
    end
  end
end

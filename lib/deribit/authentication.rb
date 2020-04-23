require 'base64'
require 'digest'

module Deribit
  # Deribit authentication implemented as Faraday middleware
  # @see https://docs.deribit.com/#authentication
  class Authentication < Faraday::Middleware
    def initialize(app, key, secret)
      super(app)
      @key = key
      @secret = secret
    end

    def call(env)
      return @app.call(env) if env['url'].path.include? 'public'
      return @app.call(env) if @key.nil? || @secret.nil?

      timestamp = Time.now.utc.to_i * 1000
      nonce = rand(999999)
      env.request_headers['Authorization'] = header env, timestamp, nonce

      @app.call env
    end

    # Authorization: deri-hmac-sha256 id=ClientId,ts=Timestamp,sig=Signature,nonce=Nonce
    def header(env, timestamp, nonce)
      signature = Deribit.http_signature env, timestamp, nonce, @secret
      "deri-hmac-sha256 id=#{@key},ts=#{timestamp},sig=#{signature},nonce=#{nonce}"
    end
  end
end

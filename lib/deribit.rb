require 'faraday'
require 'faraday_middleware'
require 'hashie'
require 'faye/websocket'

require 'deribit/version'
require 'deribit/client'
require 'deribit/authentication'
require 'deribit/websocket'
require 'deribit/http'

# Root module
module Deribit
  # Base error class
  class Error < StandardError; end

  # @see https://docs.deribit.com/rpc-authentication.html
  def self.signature(key, nonce, params, query)
    signature_string = params.map { |k, v| "#{k}=#{v}" }.sort.join '&'
    signature_string += "&#{query}" if query

    signature_digest = Digest::SHA256.digest signature_string
    signature_hash = Base64.encode64 signature_digest

    "#{key}.#{nonce}.#{signature_hash.chomp}"
  end
end

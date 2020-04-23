# frozen_string_literal: true

require 'openssl'
require 'faraday'
require 'faraday_middleware'
require 'faraday/detailed_logger'
require 'hashie'
# require 'faye/websocket'
require 'websocket-client-simple'

require 'deribit/version'
require 'deribit/client'
require 'deribit/authentication'
require 'deribit/websocket'
require 'deribit/http'
require 'deribit/naming'

# Root module
module Deribit
  # Base error class
  class Error < StandardError; end
  class NotImplementedError < Error; end

  # @see https://docs.deribit.com/#authentication
  def self.http_signature(env, timestamp, nonce, secret)
    # RequestData = UPPERCASE(HTTP_METHOD()) + "\n" + URI() + "\n" + RequestBody + "\n";
    uri = env['url'].path.dup
    uri << '?' << env['url'].query if env['url'].query
    request_data = [env['method'].upcase, uri, env['body'], ''].join "\n"

    signature timestamp, nonce, request_data, secret
  end

  # @see https://docs.deribit.com/#authentication
  def self.signature(timestamp, nonce, data, secret)
    # StringToSign = Timestamp + "\n" + Nonce + "\n" + Data;
    # Signature = HEX_STRING( HMAC-SHA256( ClientSecret, StringToSign ) );
    string_to_sign = [timestamp, nonce, data].join "\n"
    ::OpenSSL::HMAC.hexdigest('SHA256', secret, string_to_sign)
  end
end

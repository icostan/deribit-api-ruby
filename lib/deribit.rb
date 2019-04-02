require 'faraday'
require 'faraday_middleware'
require 'hashie'
require 'faye/websocket'

require 'deribit/version'
require 'deribit/client'
require 'deribit/authentication'
require 'deribit/websocket'

# Root module
module Deribit
  # Base error class
  class Error < StandardError; end
end

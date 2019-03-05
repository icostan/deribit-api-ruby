require 'faraday'
require 'faraday_middleware'
require 'hashie'

require 'deribit/version'
require 'deribit/client'
require 'deribit/authentication'

# Root module
module Deribit
  # Base error class
  class Error < StandardError; end
end

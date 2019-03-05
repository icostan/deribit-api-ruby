require 'dotenv'
Dotenv.load
Dotenv.require_keys('API_KEY', 'API_SECRET')

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'deribit-api'
require 'minitest/autorun'

#!/usr/bin/env ruby

require 'bundler/setup'
require 'deribit-api'

puts "==> Watching BTC/ETH whales...\n"

client = Deribit::Client.new

# for BTC
client.trades instrument_name: 'BTC-PERPETUAL' do |trade|
  baseNotional = trade.amount / trade.price
  puts "BTC: #{trade.direction} #{baseNotional} @ #{trade.price}" if baseNotional > 1
end

# for ETH
client.trades instrument_name: 'ETH-PERPETUAL' do |trade|
  baseNotional = trade.amount / trade.price
  puts "ETH: #{trade.direction} #{baseNotional} @ #{trade.price}" if baseNotional > 10
end

# endless
loop do
  sleep 1
end

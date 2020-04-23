#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubygems'
require 'websocket-client-simple'
require 'json'

ws = WebSocket::Client::Simple.connect 'wss://www.deribit.com/ws/api/v2'

ws.on :message do |msg|
  p "msg: #{msg.data}"
end

ws.on :open do |e|
  p "open: #{e}"
end

ws.on :close do |e|
  p "close: #{e}"
  exit 1
end

ws.on :error do |e|
  p "error: #{e}"
end

sleep 3

puts 'Subscribing...'
payload = {
  'jsonrpc' => '2.0',
  'method' => 'public/subscribe',
  'id' => 66,
  'params' => {
    'channels' => ['trades.BTC-PERPETUAL.raw']
  }
}
ws.send payload.to_json.to_s

while ws.open? do
  sleep 1
  puts 'Running...'
end

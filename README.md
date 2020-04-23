# Deribit

[![Build Status](https://travis-ci.org/icostan/deribit-api-ruby.svg?branch=master)](https://travis-ci.org/icostan/deribit-api-ruby)
[![Maintainability](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/maintainability)](https://codeclimate.com/github/icostan/deribit-api-ruby/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/test_coverage)](https://codeclimate.com/github/icostan/deribit-api-ruby/test_coverage)
[![Inline docs](http://inch-ci.org/github/icostan/deribit-api-ruby.svg?branch=master)](http://inch-ci.org/github/icostan/deribit-api-ruby)
[![Gem Version](https://badge.fury.io/rb/deribit-api.svg)](https://badge.fury.io/rb/deribit-api)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/gems/deribit-api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/icostan/deribit-api-ruby/blob/master/LICENSE)

Idiomatic Ruby library for [Deribit API 2.0](https://docs.deribit.com)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'deribit-api'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install deribit-api

## Usage

### Overview

```ruby
require 'deribit-api'

# for public data only
client = Deribit::Client.new

# for private data pass KEY and SECRET
client = Deribit::Client.new key: 'KEY', secret: 'SECRET'
```

Get trades via HTTP APIs and idiomatic Ruby:

```ruby
trades = client.trades instrument_name: 'BTC-PERPETUAL', count: 3
trades.first
=> #<Hashie::Mash amount=770.0 direction="sell" index_price=7088.57 instrument_name="BTC-PERPETUAL" price=7088.5 tick_direction=3 timestamp=1587632258141 trade_id="73366505" trade_seq=45738005>
trades.first.instrument_name
=> "BTC-PERPETUAL"
```

Streaming trades via Websocket APIs and idiomatic Ruby:

```ruby
client.trades(instrument_name: 'BTC-PERPETUAL') do |trade|
	puts trade
end
=> #<Hashie::Mash amount=10.0 direction="sell" index_price=7076.01 instrument_name="BTC-PERPETUAL" price=7076.0 tick_direction=3 timestamp=1587632546493 trade_id="73366877" trade_seq=45738278>
```

Access generic HTTP API endpoints: <https://docs.deribit.com/#market-data>

```ruby
result = client.http.get '/public/ping'
=> "pong"
```

Access generic Websocket API channels: <https://docs.deribit.com/#subscriptions>

```ruby
client.websocket.subscribe 'user.portofolio.BTC' do |data|
	puts data
end
```

### Examples

Fetch all tradable instruments:

```ruby
instruments = client.instruments
instruments.first
=> #<Hashie::Mash base_currency="BTC" contract_size=1.0 creation_timestamp=1587024008000 expiration_timestamp=1588320000000 instrument_name="BTC-1MAY20-6750-C" is_active=true kind="option" maker_commission=0.0004 min_trade_amount=0.1 option_type="call" quote_currency="USD" settlement_period="week" strike=6750.0 taker_commission=0.0004 tick_size=0.0005>
```

Orderbook for BTCUSD perpetual instrument:

```ruby
orderbook = client.book instrument_name: 'BTC-PERPETUAL', depth: 3
puts orderbook.asks.first
```

Orderbook streaming via websocket:

```ruby
client.book instrument_name: 'ETH-PERPETUAL', group: 1, depth: 3 do |book|
  puts book
end
```

 Place a BTCUSD limit buy order 100 contracts @ 2500:

```ruby
response = client.buy 'BTC-PERPETUAL', 100, price: 2500
puts response.order.state
```

Account  info:

```ruby
account = client.account
=> #<Hashie::Mash available_funds=9.99958335 available_withdrawal_funds=9.99958335 balance=9.99958335 currency="BTC" delta_total=0.0 deposit_address="2N9KizxwYNrKgd22QfSz9zxT4EPR4uAsWYr" equity=9.99958335 futures_pl=0.0 futures_session_rpl=0.0 futures_session_upl=0.0 initial_margin=0.0 limits=#<Hashie::Mash matching_engine=2 matching_engine_burst=20 non_matching_engine=200 non_matching_engine_burst=300> maintenance_margin=0.0 margin_balance=9.99958335 options_delta=0.0 options_gamma=0.0 options_pl=0.0 options_session_rpl=0.0 options_session_upl=0.0 options_theta=0.0 options_value=0.0 options_vega=0.0 portfolio_margining_enabled=false session_funding=0.0 session_rpl=0.0 session_upl=0.0 total_pl=0.0>
account.equity
=> 9.99958335
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rake` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/icostan/deribit-api-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Deribit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/icostan/deribit/blob/master/CODE_OF_CONDUCT.md).

# Deribit

[![Build Status](https://travis-ci.org/icostan/deribit-api-ruby.svg?branch=master)](https://travis-ci.org/icostan/deribit-api-ruby)
[![Maintainability](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/maintainability)](https://codeclimate.com/github/icostan/deribit-api-ruby/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/test_coverage)](https://codeclimate.com/github/icostan/deribit-api-ruby/test_coverage)
[![Inline docs](http://inch-ci.org/github/icostan/deribit-api-ruby.svg?branch=master)](http://inch-ci.org/github/icostan/deribit-api-ruby)
[![Gem Version](https://badge.fury.io/rb/deribit-api.svg)](https://badge.fury.io/rb/deribit-api)
[![Yard Docs](https://img.shields.io/badge/yard-docs-blue.svg)](https://www.rubydoc.info/gems/deribit-api)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/icostan/deribit-api-ruby/blob/master/LICENSE)

Ruby library for [Deribit API](https://docs.deribit.com)

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
```

Create a simple client to access public APIs

```ruby
client = Deribit::Client.new
trades = client.trades 'options', count: 3
trades.first
  => #<Hashie::Mash amount=3.0 direction="buy" indexPrice=3817.31 instrument="BTC-29MAR19-4500-C" iv=60.33 price=0.016 quantity=3.0 tickDirection=0 timeStamp=1551274556589 tradeId=16055937 tradeSeq=712>
trades.first.instrument
  => "BTC-29MAR19-4500-C"
```

Pass key and secret to access private APIs

```ruby
client = Deribit::Client.new key: 'KEY', secret: 'SECRET'
account = client.account
 => #<Hashie::Mash PNL=0.0 SRPL=0.0 SUPL=0.0 availableFunds=9.99995789 balance=9.99995789 currency="BTC" deltaTotal=0.0 depositAddress="2N6SU5Yjn7AfYcT89QyeeHvHyZoqTt2GLyi" equity=9.999957896 futuresPNL=0.0 futuresSRPL=0.0 futuresSUPL=0.0 initialMargin=0.0 maintenanceMargin=0.0 marginBalance=9.99995789 optionsD=0.0 optionsG=0.0 optionsPNL=0.0 optionsSRPL=0.0 optionsSUPL=0.0 optionsTh=0.0 optionsV=0.0 sessionFunding=0.0>
account.equity
  => 9.999957896
```

### Examples

Fetch all tradable instruments:

```ruby
instruments = client.instruments
puts instruments.first
```

Orderbook for BTCUSD perpetual instrument:

```ruby
orderbook = client.orderbook 'BTC-PERPETUAL', depth: 3
puts orderbook.asks.first
```

 Place a BTCUSD limit buy order 100 contracts @ 2500:

```ruby
response = client.buy 'BTC-PERPETUAL', 100, price: 2500
puts response.order.state
```

Get last 10 option trades:

```ruby
trades = client.trades 'options', count: 10
puts trades.first
```

Options trading summary:

```ruby
summaries = client.summary :options
puts summaries.first
```

## API Endpoints

All endpoints marked with [X] are fully implemented and ready to use, see the features table below:

API endpoints | Private? | HTTP API | Websocket API | FIX API |
--------------|----------|----------|---------------|---------|
Time || [X] | [X] ||
Setheartbeat || N/A | [X] ||
Cancelheartbeat || N/A | [X] ||
Test || [X] | [X] ||
Ping || [X] | [X] ||
Instruments || [X] | [X] ||
Currencies || [X] | [X] ||
Index || [X] | [X] ||
Orderbook || [X] | [X] ||
Trades || [X] | [X] ||
Summary || [X] | [X] ||
Announcements || [X] | [X] ||
Settlements || [X] | [X] ||
Account | YES | [X] ||
Buy | YES | [X] ||
Sell | YES | [X] ||
Edit | YES | [X] ||
Cancel | YES | [X] ||
Cancel all | YES | [X] ||
Orders | YES | [X] ||
Positions | YES | [X] ||
Orders history | YES | [X] ||
Order | YES | [X] ||
Trades history | YES | [X] ||
New announcements | YES | [X] ||
Cancel on disconnect | YES | [X] ||
Get email lang | YES | [X] ||
Set email lang | YES | [X] ||
Set announcements read | YES | [X] ||
Settlements history | YES | [X] ||

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/icostan/deribit-api-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Deribit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/icostan/deribit/blob/master/CODE_OF_CONDUCT.md).

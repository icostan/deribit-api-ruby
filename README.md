# Deribit

[![Build Status](https://travis-ci.org/icostan/deribit-api-ruby.svg?branch=master)](https://travis-ci.org/icostan/deribit-api-ruby)
[![Maintainability](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/maintainability)](https://codeclimate.com/github/icostan/deribit-api-ruby/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/1e100fc78c8ebaa8b4b5/test_coverage)](https://codeclimate.com/github/icostan/deribit-api-ruby/test_coverage)
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

client = Deribit::Client.new

trades = client.trades 'options', count: 3
trades.first
  => #<Hashie::Mash amount=3.0 direction="buy" indexPrice=3817.31 instrument="BTC-29MAR19-4500-C" iv=60.33 price=0.016 quantity=3.0 tickDirection=0 timeStamp=1551274556589 tradeId=16055937 tradeSeq=712>
trades.first.instrument
  => "BTC-29MAR19-4500-C"
```

### API Endpoints

#### Instruments

```ruby
instruments = client.instruments
puts instruments.first
```

#### Currencies

```ruby
currencies = client.currencies
puts currencies.first
```

#### Orderbook

```ruby
orderbook = client.orderbook 'BTC-PERPETUAL', depth: 3
puts orderbook.bids.first
```

#### Trades

```ruby
trades = client.trades 'options', count: 3
puts trades.first
```

#### Summary


```ruby
summaries = client.summary :futures
puts summaries.first
```

#### Announcements

```ruby
announcements = client.announcements
puts announcements.first
```

#### Settlements

```ruby
settlements = client.settlements
puts settlements.first
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/icostan/deribit-api-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the Deribit project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/icostan/deribit/blob/master/CODE_OF_CONDUCT.md).

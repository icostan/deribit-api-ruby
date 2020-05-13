# frozen_string_literal: true

module Deribit
  # @author Iulian Costan (deribit-api@iuliancostan.com)
  # TODO: refactor and clean this up
  module Naming
    def self.trades_channel(options)
      private = options.delete :private
      trades = private ? 'user.trades' : 'trades'
      channel trades, options
    end

    def self.trades_uri(options)
      private = options.delete :private
      uri = private ? 'private/get_user_trades' : 'public/get_last_trades'
      uri += by_instrument(options) + by_currency(options)
      uri += options[:end_timestamp] ? '_and_time' : ''
      uri
    end

    def self.book_channel(options)
      'book' + for_instrument(options) + with_group_and_depth(options) + with_interval(options)
    end

    def self.channel(prefix, options)
      prefix + channel_suffix(options)
    end

    def self.channel_for_instrument(prefix, options)
      prefix + for_instrument(options)
    end

    def self.instrument_with_interval(prefix, options)
      prefix + for_instrument(options) + with_interval(options)
    end

    def self.cancel_uri(options)
      '/private/cancel_all' + by_instrument(options) + by_currency(options)
    end

    def self.orders_uri(options)
      '/private/get_open_orders' + by_instrument(options) + by_currency(options)
    end

    def self.by_instrument(options)
      options[:instrument_name] ? '_by_instrument' : ''
    end

    def self.by_currency(options)
      options[:currency] ? '_by_currency' : ''
    end

    def self.for_instrument(options)
      raise 'instrument_name param is required' unless options[:instrument_name]

      ".#{options[:instrument_name]}"
    end

    def self.with_interval(options)
      interval = options[:interval] || '100ms'
      ".#{interval}"
    end

    def self.with_group_and_depth(options)
      if options[:group] || options[:depth]
        group = options[:group] || '5'
        depth = options[:depth] || '10'
        ".#{group}.#{depth}"
      else
        ''
      end
    end

    def self.channel_suffix(options)
      currency = options[:currency]
      instrument_name = options[:instrument_name]
      kind = options[:kind] || 'any'
      interval = options[:interval] || 'raw'
      if instrument_name
        ".#{instrument_name}.#{interval}"
      elsif currency
        ".#{kind}.#{currency}.#{interval}"
      else
        raise 'invalid args'
      end
    end
  end
end

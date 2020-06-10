# frozen_string_literal: true

module Deribit
  # @author Iulian Costan (deribit-api@iuliancostan.com)
  module Naming
    def trades_channel(options)
      private = options.delete :private
      trades = private ? 'user.trades' : 'trades'
      channel trades, options
    end

    def trades_uri(options)
      private = options.delete :private
      uri = private ? 'private/get_user_trades' : 'public/get_last_trades'
      uri += by_instrument(options) + by_currency(options)
      uri += options[:end_timestamp] ? '_and_time' : ''
      uri
    end

    def book_channel(options)
      'book' + for_instrument(options) + with_group_and_depth(options) + with_interval(options)
    end

    def channel(prefix, options)
      channel = prefix
      channel += for_instrument(options) if options[:instrument_name]
      channel += for_currency(options) if options[:currency]
      channel += with_interval(options)
      channel
    end

    def channel_for_instrument(prefix, options)
      prefix + for_instrument(options)
    end

    def instrument_with_interval(prefix, options)
      prefix + for_instrument(options) + with_interval(options)
    end

    def cancel_uri(options)
      '/private/cancel_all' + by_instrument(options) + by_currency(options)
    end

    def orders_uri(options)
      '/private/get_open_orders' + by_instrument(options) + by_currency(options)
    end

    def by_instrument(options)
      options[:instrument_name] ? '_by_instrument' : ''
    end

    def by_currency(options)
      options[:currency] ? '_by_currency' : ''
    end

    def for_instrument(options)
      raise 'instrument_name param is required' unless options[:instrument_name]

      ".#{options[:instrument_name]}"
    end

    def for_currency(options)
      raise 'currency param is required' unless options[:currency]

      kind = options[:kind] || 'any'
      ".#{kind}.#{options[:currency]}"
    end

    def with_interval(options)
      interval = options[:interval] || '100ms'
      ".#{interval}"
    end

    def with_group_and_depth(options)
      if options[:group] || options[:depth]
        group = options[:group] || '5'
        depth = options[:depth] || '10'
        ".#{group}.#{depth}"
      else
        ''
      end
    end
  end
end

# frozen_string_literal: true

require 'json'

module Split
  module Persistence
    class CookieAdapter
      def initialize(context)
        @cookies = context.send(:cookies)
        @expires = Time.now + cookie_length_config
      end

      def [](key)
        hash[key]
      end

      def multi_get(*keyss)
        keyss.map { |key| hash[key] }
      end

      def []=(key, value)
        set_cookie(hash.merge(key => value))
      end

      # TODO: do in atomic fashion like redis' setnx
      # (or another way to handle race condition)
      def setnx(key, value)
        self[key] = value unless self[key]
      end

      def delete(*keyss)
        set_cookie(
          hash.tap do |h|
            keyss.each do |key|
              h.delete(key)
            end
          end
        )
      end

      def keys
        hash.keys
      end

      private

      def set_cookie(value)
        @cookies[:split] = {
          value: JSON.generate(value),
          expires: @expires
        }
      end

      def hash
        if @cookies[:split]
          begin
            JSON.parse(@cookies[:split])
          rescue JSON::ParserError
            {}
          end
        else
          {}
        end
      end

      def cookie_length_config
        Split.configuration.persistence_cookie_length
      end
    end
  end
end

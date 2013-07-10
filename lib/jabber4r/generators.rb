# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>
# Copyright (C) 2013  Mikhail Usvyatsov <miha-usv@yandex.ru>

require "securerandom"

module Jabber
  # Public: This class provides sequences and identifiers generator
  class Generators
    include SecureRandom

    # Creates instance of Rid
    #
    # Returns Rid
    def self.request
      Rid.new
    end

    # Creates unique string
    #
    # prefix - String, prefix of string
    #
    # Returns String
    def self.id(prefix = "id")
      [prefix, SecureRandom.uuid] * "-"
    end

    # Creates unique string with "iq-" prefix
    #
    # Returns String
    def self.iq
      id("iq")
    end

    # Creates unique string with "thread-" prefix
    #
    # Returns String
    def self.thread
      id("thread")
    end

    # Public: This class provides request sequence iterator
    #
    # Examples
    #
    # rid = Jabber::Generators::Rid.new
    # rid.value # => 100000000
    # rid.next # => 100000001
    class Rid
      attr_reader :value

      def initialize
        @value = Random.new_seed
      end

      # Increments rid value
      #
      # Returns Bignum
      def next
        @value = value.next
      end
    end
  end
end

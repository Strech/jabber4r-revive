# coding: utf-8
require "securerandom"

module Jabber
  class Generators
    include SecureRandom

    # Creates instance of Rid
    #
    # Returns Rid object
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
  end

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

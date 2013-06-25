# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require "singleton"
require "logger"

module Jabber
  # Produces debug methods
  #
  # Example
  #
  # def warn(message)
  #   Debug.instance.send(:warn, message)
  # end
  # module_function m
  [:warn, :debug, :info].each do |m|
    define_method(m) do |message|
      Debugger.send(m, message)
    end
    module_function m
  end

  class Debugger
    include Singleton

    attr_accessor :enabled, :logger

    def initialize
      @logger  = Logger.new(STDOUT)
      @enabled = false
    end

    class << self
      def logger=(logger)
        instance.logger = logger
      end

      def enable!
        instance.enabled = true
      end

      def disable!
        instance.enabled = false
      end

      def enabled?
        instance.enabled
      end

      [:warn, :debug, :info].each do |m|
        define_method(m) do |message|
          enabled? && instance.logger.send(m, message)
        end
      end
    end # class << self
  end
end
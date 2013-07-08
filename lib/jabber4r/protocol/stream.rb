# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber::Protocol
  # Public: This class provide methods for generating stream XML
  class Stream
    # Public: The jabber session
    attr_reader :session

    def initialize(session)
      @session = session
    end

    # Internal: Generates an open stream XML for session
    #
    # Returns String
    def open
      [head, open_stream] * "\n"
    end

    # Internal: Generates an close stream XML for session
    #
    # Returns String
    def close
      close_stream
    end

    private
    # Internal: Generates an open stream
    #
    # Returns String
    def open_stream
      %Q[<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="#{session.domain}" version="1.0">]
    end

    # Internal: Generates an close stream
    #
    # Returns String
    def close_stream
      "</stream:stream>"
    end

    # Internal: Generates head of stream
    #
    # Returns String
    def head
      %Q[<?xml version="1.0" encoding="UTF-8"?>]
    end
  end
end
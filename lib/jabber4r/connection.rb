# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber
  # The connection class encapsulates the connection to the Jabber
  # service including managing the socket and controlling the parsing
  # of the Jabber XML stream.
  class Connection
    DISCONNECTED = 1
    CONNECTED = 2

    # Public
    attr_reader :host, :port, :status, :input, :output

    # Internal
    attr_reader :poll_thread, :parser_thread, :socket, :filters

    def initialize(host, port = 5222)
      @host, @port = host, port

      @threadBlocks = {}
      @filters = {}

      @pollCounter = 10
      @mutex = Mutex.new

      @status = DISCONNECTED
    end

    # Connects to the Jabber server through a TCP Socket and
    # starts the Jabber parser.
    #
    # Returns nothing
    def connect
      @socket = TCPSocket.new(@host, @port)
      @parser = Jabber::Protocol.Parser.new(@socket, self)
      @parser_thread = Thread.new { @parser.parse }
      @poll_thread   = Thread.new { poll }

      @status = CONNECTED
    end

    # Closes the connection to the Jabber service
    #
    # Returns nothing
    def close
      parser_thread.kill if parser_thread # why if?
      poll_thread.kill
      socket.close if socket

      @status = DISCONNECTED
    end
    alias :disconnect :close

    # Returns if this connection is connected to a Jabber service
    #
    # Returns boolean
    def connected?
      status == CONNECTED
    end

    # Returns if this connection is NOT connected to a Jabber service
    #
    # Returns boolean
    def disconnected?
      status == DISCONNECTED
    end

    # Adds a filter block to process received XML messages
    #
    # name - String the name of filter
    # block - Block of code
    #
    # Returns nothing
    def add_filter(name, &block)
      raise ArgumentError, "Expected block to be given" if block.nil?

      @filters[name] = block
    end

    # Removes a filter block
    #
    # name - String the name of filter
    #
    # Returns Block of code
    def remove_filter(name)
      filters.delete(name)
    end

    ############################################################################
    #                 All that under needs to be REFACTORED                    #
    ############################################################################

    ##
    # Mounts a block to handle exceptions if they occur during the
    # poll send.  This will likely be the first indication that
    # the socket dropped in a Jabber Session.
    #
    def on_connection_exception(&block)
      @exception_block = block
    end

    def parse_failure
      Thread.new {@exception_block.call if @exception_block}
    end

    # Receiving xml element, and processing it
    # NOTE: Synchonized by Mutex
    #
    # xml_element - ParsedXMLElement the received from socket xml element
    #
    # Returns nothing
    def receive(xml_element)
      @mutex.synchronize { dirty_receive(xml_element) }
    end

    # Receiving xml element, and processing it
    # NOTE: Synchonized by Mutex
    #
    # xml         - String the string containing xml
    # proc_object - Proc the proc object to call (default: nil)
    # block       - Block of ruby code
    #
    # Returns nothing
    def send(xml, proc_object = nil, &block)
      @mutex.synchronize { dirty_send(xml, proc_object, &block) }
    end

    ##
    # Starts a polling thread to send "keep alive" data to prevent
    # the Jabber connection from closing for inactivity.
    #
    def poll
      sleep 10
      while true
        sleep 2
        @pollCounter = @pollCounter - 1
        if @pollCounter < 0
          begin
            send("  \t  ")
          rescue
            Thread.new {@exception_block.call if @exception_block}
            break
          end
        end
      end
    end

    private
    ##
    # Processes a received ParsedXMLElement and executes
    # registered thread blocks and filters against it.
    #
    # element:: [ParsedXMLElement] The received element
    #
    def dirty_receive(element)
      while @threadBlocks.size==0 && @filters.size==0
        sleep 0.1
      end
      Jabber::DEBUG && puts("RECEIVED:\n#{element.to_s}")
      @threadBlocks.each do |thread, proc|
        begin
          proc.call(element)
          if element.element_consumed?
            @threadBlocks.delete(thread)
            thread.wakeup if thread.alive?
            return
          end
        rescue Exception => error
          puts error.to_s
          puts error.backtrace.join("\n")
        end
      end
      @filters.each_value do |proc|
        begin
          proc.call(element)
          return if element.element_consumed?
        rescue Exception => error
          puts error.to_s
          puts error.backtrace.join("\n")
        end
      end
    end # def dirty_receive

    ##
    # Sends XML data to the socket and (optionally) waits
    # to process received data.
    #
    # xml:: [String] The xml data to send
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    #
    def dirty_send(xml, proc=nil, &block)
      Jabber::DEBUG && puts("SENDING:\n#{ xml.kind_of?(String) ? xml : xml.to_s }")
      xml = xml.to_s if not xml.kind_of? String
      block = proc if proc
      @threadBlocks[Thread.current]=block if block
      begin
        @socket << xml
      rescue
        raise JabberConnectionException.new(true, xml)
      end
      @pollCounter = 10
    end # def dirty_send
  end
end

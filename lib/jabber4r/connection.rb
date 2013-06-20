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

    attr_reader :host, :port, :status, :input, :output

    def initialize(host, port=5222)
      @host = host
      @port = port
      @status = DISCONNECTED
      @filters = {}
      @threadBlocks = {}
      @pollCounter = 10
      @mutex = Mutex.new
    end

    ##
    # Connects to the Jabber server through a TCP Socket and
    # starts the Jabber parser.
    #
    def connect
      @socket = TCPSocket.new(@host, @port)
      @parser = Jabber::Protocol.Parser.new(@socket, self)
      @parserThread = Thread.new {@parser.parse}
      @pollThread = Thread.new {poll}
      @status = CONNECTED
    end

    ##
    # Mounts a block to handle exceptions if they occur during the
    # poll send.  This will likely be the first indication that
    # the socket dropped in a Jabber Session.
    #
    def on_connection_exception(&block)
      @exception_block = block
    end

    def parse_failure(exception = nil)
      Thread.new { @exception_block.call(exception) if @exception_block }
    end

    ##
    # Returns if this connection is connected to a Jabber service
    #
    # return:: [Boolean] Connection status
    #
    def connected?
      status == CONNECTED
    end

    ##
    # Returns if this connection is NOT connected to a Jabber service
    #
    # return:: [Boolean] Connection status
    #
    def disconnected?
      status == DISCONNECTED
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

    ##
    # Adds a filter block/proc to process received XML messages
    #
    # xml:: [String] The xml data to send
    # proc:: [Proc = nil] The optional proc
    # &block:: [Block] The optional block
    #
    def add_filter(ref, proc=nil, &block)
      block = proc if proc
      raise "Must supply a block or Proc object to the addFilter method" if block.nil?
      @filters[ref] = block
    end

    def delete_filter(ref)
      @filters.delete(ref)
    end

    ##
    # Closes the connection to the Jabber service
    #
    def close
      @parserThread.kill if @parserThread
      @pollThread.kill
      @socket.close if @socket
      @status = DISCONNECTED
    end

    def force_close!
      close

      @threadBlocks.each do |thread, _|
        thread.raise("Connection was force closed")
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
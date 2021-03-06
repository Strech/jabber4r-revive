# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  # The connection class encapsulates the connection to the Jabber
  # service including managing the socket and controlling the parsing
  # of the Jabber XML stream.
  class Connection
    DISCONNECTED = 1
    CONNECTED = 2

    # Public
    attr_reader :domain, :port, :status, :input, :output

    # Internal
    attr_reader :poll_thread, :parser_thread

    # Internal
    attr_reader :filters, :handlers

    # Internal
    attr_reader :socket, :parser

    def initialize(domain, port = 5222)
      @domain, @port = domain, port

      @handlers, @filters = {}, {}

      @poll_counter = 10
      @mutex = Mutex.new

      @status = DISCONNECTED
    end

    # Public: Connects to the Jabber server through a TCP Socket and
    # starts the Jabber parser.
    #
    # Returns nothing
    def connect
      @socket = TCPSocket.new(@domain, @port)
      @parser = Jabber::Protocol.Parser.new(socket, self)

      register_parsing_thread
      register_polling_thread

      @status = CONNECTED
    end

    # Internal: Register new parser thread
    #
    # Returns nothing
    def register_parsing_thread
      @parser_thread = Thread.new { parser.parse }
    end

    # Internal: Register new polling thread
    #
    # Returns nothing
    def register_polling_thread
      @poll_thread = Thread.new { poll }
    end

    # Public: Closes the connection to the Jabber service
    #
    # Returns nothing
    def close
      parser_thread.kill if parser_thread # why if?
      poll_thread.kill
      socket.close if socket

      @status = DISCONNECTED
    end
    alias :disconnect :close

    # Public: Returns if this connection is connected to a Jabber service
    #
    # Returns boolean
    def connected?
      status == CONNECTED
    end

    # Public: Returns if this connection is NOT connected to a Jabber service
    #
    # Returns boolean
    def disconnected?
      status == DISCONNECTED
    end

    # Public: Adds a filter block to process received XML messages
    #
    # name - String the name of filter
    # block - Block of code
    #
    # Returns nothing
    def add_filter(name, &block)
      raise ArgumentError, "Expected block to be given" if block.nil?

      @filters[name] = block
    end

    # Public: Removes a filter block
    #
    # name - String the name of filter
    #
    # Returns Block of code
    def remove_filter(name)
      filters.delete(name)
    end

    # Public: Receiving xml element, and processing it
    # NOTE: Synchonized by Mutex
    #
    # xml         - String the string containing xml
    # proc_object - Proc the proc object to call (default: nil)
    # block       - Block of ruby code
    #
    # Returns nothing
    def send(xml, proc_object = nil, &block)
      @mutex.synchronize { write_to_socket(xml, proc_object, &block) }
    end

    # Public: Receiving xml element, and processing it
    # NOTE: Synchonized by Mutex
    #
    # xml_element - ParsedXMLElement the received from socket xml element
    #
    # Returns nothing
    def receive(xml)
      @mutex.synchronize { process_xml_from_socket(xml) }
    end

    # Internal: Sends XML data to the socket and (optionally) waits
    # to process received data.
    # NOTE: If both habdler and block are given, handler has higher proirity
    #
    # xml     - String the xml data to send
    # handler - [Proc|Lambda|#call] the proc object or labda to handle response data (optional)
    # block   - Block the block of ruby code (optional)
    #
    # Returns nothing
    def write_to_socket(xml, handler = nil, &block)
      Jabber.debug("SENDING:\n#{xml}")

      handler = block if handler.nil?
      handlers[Thread.current] = handler unless handler.nil?

      socket.write(xml)

      @poll_counter = 10
    end

    # Internal: Processes a received ParsedXMLElement and executes
    # registered handlers and filters against it
    #
    # xml - ParsedXMLElement The received element
    #
    # Returns nothing
    def process_xml_from_socket(xml)
      sleep 0.1 while wait_for_consume?

      Jabber.debug("RECEIVED:\n#{xml}")

      consume_xml_by_handlers(xml) || consume_xml_by_filters(xml)
    end

    # Internal: Processes a received ParsedXMLElement by handlers
    #
    # xml - ParsedXMLElement The received element
    #
    # Returns boolean
    def consume_xml_by_handlers(xml)
      handlers.each do |thread, block|
        begin
          block.call(xml)

          if xml.element_consumed?
            handlers.delete(thread)
            thread.wakeup if thread.alive?

            return true
          end
        rescue Exception => error
          puts error.to_s
          puts error.backtrace.join("\n")
        end
      end

      false
    end

    # Internal: Processes a received ParsedXMLElement by filters
    #
    # xml - ParsedXMLElement The received element
    #
    # Returns boolean
    def consume_xml_by_filters(xml)
      filters.each_value do |block|
        begin
          block.call(xml)

          return true if xml.element_consumed?
        rescue Exception => error
          puts error.to_s
          puts error.backtrace.join("\n")
        end
      end

      false
    end

    # Internal: Should we wait for next part of socket data
    #
    # Returns boolean
    def wait_for_consume?
      handlers.size.zero? && filters.size.zero?
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

    ############################################################################
    #                 All that under needs to be REFACTORED                    #
    ############################################################################

    ##
    # Starts a polling thread to send "keep alive" data to prevent
    # the Jabber connection from closing for inactivity.
    #
    def poll
      sleep 10
      while true
        sleep 2
        @poll_counter = @poll_counter - 1
        if @poll_counter < 0
          begin
            send("  \t  ")
          rescue
            Thread.new {@exception_block.call if @exception_block}
            break
          end
        end
      end
    end
  end
end

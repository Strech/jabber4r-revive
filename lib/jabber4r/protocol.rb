# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

require "singleton"
require "socket"

module Jabber
  ##
  # The Protocol module contains helper methods for constructing
  # Jabber protocol elements and classes that implement protocol
  # elements.
  #
  module Protocol

    USE_PARSER = :rexml # either :rexml or :xmlparser

    ##
    # The parser to use for stream processing.  The current
    # available parsers are:
    #
    # * Jabber::Protocol::ExpatJabberParser uses XMLParser
    # * Jabber::Protocol::REXMLJabberParser uses REXML
    #
    # return:: [Class] The parser class
    #
    def Protocol.Parser
      if USE_PARSER==:xmlparser
        Jabber::Protocol::ExpatJabberParser
      else
        Jabber::Protocol::REXMLJabberParser
      end
    end

    ##
    # Generates an open stream XML element
    #
    # domain:: [String] The domain being connected to
    # return:: [String] The XML data to send
    #
    def self.gen_open_stream(domain)
      return ('<?xml version="1.0" encoding="UTF-8" ?><stream:stream to="'+domain+'" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" version="1.0">')
    end

    ##
    # Generates an close stream XML element
    #
    # return:: [String] The XML data to send
    #
    def self.gen_close_stream
      return "</stream:stream>"
    end

    if USE_PARSER == :xmlparser
      require 'xmlparser'
      ##
      # The ExpatJabberParser uses XMLParser (expat) to parse the incoming XML stream
      # of the Jabber protocol and fires ParsedXMLElements at the Connection
      # instance.
      #
      class ExpatJabberParser

        # status if the parser is started
        attr_reader :started

        ##
        # Constructs a parser for the supplied stream (socket input)
        #
        # stream:: [IO] Socket input stream
        # listener:: [#receive(ParsedXMLElement)] The listener (usually a Jabber::Protocol::Connection instance
        #
        def initialize(stream, listener)
          @stream = stream
          def @stream.gets
            super(">")
          end
          @listener = listener
        end

        ##
        # Begins parsing the XML stream and does not return until
        # the stream closes.
        #
        def parse
          @started = false

          parser = XMLParser.new("UTF-8")
          def parser.unknownEncoding(e)
            raise "Unknown encoding #{e.to_s}"
          end
          def parser.default
          end

          begin
            parser.parse(@stream) do |type, name, data|
              begin
              case type
                when XMLParser::START_ELEM
                  case name
                    when "stream:stream"
                      openstream = ParsedXMLElement.new(name)
                      data.each {|key, value| openstream.add_attribute(key, value)}
                      @listener.receive(openstream)
                      @started = true
                    else
                      if @current.nil?
                        @current = ParsedXMLElement.new(name.clone)
                      else
                        @current = @current.add_child(name.clone)
                      end
                      data.each {|key, value| @current.add_attribute(key.clone, value.clone)}
                  end
                when XMLParser::CDATA
                  @current.append_data(data.clone) if @current
                when XMLParser::END_ELEM
                  case name
                    when "stream:stream"
                      @started = false
                    else
                      @listener.receive(@current) unless @current.element_parent
                      @current = @current.element_parent
                  end
              end
              rescue
                puts  "Error #{$!}"
              end
            end
          rescue XMLParserError
            line = parser.line
            print "XML Parsing error(#{line}): #{$!}\n"
          end
        end
      end
    else # USE REXML
      require 'rexml/document'
      require 'rexml/parsers/sax2parser'
      require 'rexml/source'

      ##
      # The REXMLJabberParser uses REXML to parse the incoming XML stream
      # of the Jabber protocol and fires ParsedXMLElements at the Connection
      # instance.
      #
      class REXMLJabberParser
        # status if the parser is started
        attr_reader :started

        ##
        # Constructs a parser for the supplied stream (socket input)
        #
        # stream:: [IO] Socket input stream
        # listener:: [Object.receive(ParsedXMLElement)] The listener (usually a Jabber::Protocol::Connection instance
        #
        def initialize(stream, listener)
          @stream = stream

          # this hack fixes REXML version "2.7.3" and "2.7.4"
          if REXML::Version=="2.7.3" || REXML::Version=="2.7.4"
            def @stream.read(len=nil)
              len = 100 unless len
              super(len)
            end
            def @stream.gets(char=nil)
              super(">")
            end
            def @stream.readline(char=nil)
              super(">")
            end
            def @stream.readlines(char=nil)
              super(">")
            end
          end

          @listener = listener
          @current = nil
        end

        ##
        # Begins parsing the XML stream and does not return until
        # the stream closes.
        #
        def parse
          #puts "PARSE"
          @started = false
          begin
            parser = REXML::Parsers::SAX2Parser.new @stream

            parser.listen(:end_document) do
              raise Jabber::ConnectionForceCloseError
            end

            parser.listen( :start_element ) do |uri, localname, qname, attributes|
              case qname
              when "stream:stream"
                openstream = ParsedXMLElement.new(qname)
                attributes.each { |attr, value| openstream.add_attribute(attr, value) }
                @listener.receive(openstream)
                      @started = true
              else
                if @current.nil?
                  @current = ParsedXMLElement.new(qname)
                else
                  @current = @current.add_child(qname)
                end
                attributes.each { |attr, value| @current.add_attribute(attr, value) }
              end
            end
            parser.listen( :end_element ) do  |uri, localname, qname|
              case qname
              when "stream:stream"
                @started = false
              else
                @listener.receive(@current) unless @current.element_parent
                @current = @current.element_parent
              end
            end
            parser.listen( :characters ) do | text |
              @current.append_data(text) if @current
            end
            parser.listen( :cdata ) do | text |
              @current.append_data(text) if @current
            end
            parser.parse
          rescue REXML::ParseException => e
            @listener.parse_failure
          rescue Jabber::ConnectionForceCloseError => e
            @listener.parse_failure(e)
          end
        end
      end
    end # USE_PARSER
  end
end


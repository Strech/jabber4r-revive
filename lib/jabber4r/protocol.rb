# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

require "singleton"
require "socket"

module Jabber
  class JabberConnectionException < RuntimeError
    attr_reader :data

    def initialize(writing, data)
      @writing = writing
      @data = data
    end

    def writing?
      @writing
    end
  end

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
    # host:: [String] The host being connected to
    # return:: [String] The XML data to send
    #
    def Protocol.gen_open_stream(host)
      return ('<?xml version="1.0" encoding="UTF-8" ?><stream:stream to="'+host+'" xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams">')
    end

    ##
    # Generates an close stream XML element
    #
    # return:: [String] The XML data to send
    #
    def Protocol.gen_close_stream
      return "</stream:stream>"
    end

    ##
    # Utility class to create valid XML strings
    #
    class XMLElement

      # The parent XMLElement
      attr_accessor :parent

      ##
      # Construct an XMLElement for the supplied tag and attributes
      #
      # tag:: [String] XML tag
      # attributes:: [Hash = {}] The attribute hash[attribute]=value
      def initialize(tag, attributes={})
        @tag = tag
        @elements = []
        @attributes = attributes
        @data = ""
      end

      ##
      # Adds an attribute to this element
      #
      # attrib:: [String] The attribute name
      # value:: [String] The attribute value
      # return:: [Jabber::Protocol::XMLElement] self for chaining
      #
      def add_attribute(attrib, value)
        @attributes[attrib]=value
        self
      end

      ##
      # Adds data to this element
      #
      # data:: [String] The data to add
      # return:: [Jabber::Protocol::XMLElement] self for chaining
      #
      def add_data(data)
        @data += data.to_s
        self
      end

      ##
      # Sets the namespace for this tag
      #
      # ns:: [String] The namespace
      # return:: [Jabber::Protocol::XMLElement] self for chaining
      #
      def set_namespace(ns)
        @tag+=":#{ns}"
        self
      end

      ##
      # Adds cdata to this element
      #
      # cdata:: [String] The cdata to add
      # return:: [Jabber::Protocol::XMLElement] self for chaining
      #
      def add_cdata(cdata)
        @data += "<![CDATA[#{cdata.to_s}]]>"
        self
      end

      ##
      # Returns the parent element
      #
      # return:: [Jabber::Protocol::XMLElement] The parent XMLElement
      #
      def to_parent
        @parent
      end

      ##
      # Adds a child to this element of the supplied tag
      #
      # tag:: [String] The element tag
      # attributes:: [Hash = {}] The attributes hash[attribute]=value
      # return:: [Jabber::Protocol::XMLElement] newly created child element
      #
      def add_child(tag, attributes={})
        child = XMLElement.new(tag, attributes)
        child.parent = self
        @elements << child
        return child
      end

      ##
      # Adds arbitrary XML data to this object
      #
      # xml:: [String] the xml to add
      #
      def add_xml(xml)
        @xml = xml
      end

      ##
      # Recursively builds the XML string by traversing this element's
      # children.
      #
      # format:: [Boolean] True to pretty-print (format) the output string
      # indent:: [Integer = 0] The indent level (recursively more)
      #
      def to_xml(format, indent=0)
        result = ""
        result += " "*indent if format
        result += "<#{@tag}"
        @attributes.each {|attrib, value| result += (' '+attrib.to_s+'="'+value.to_s+'"') }
        if @data=="" and @elements.size==0
          result +="/>"
          result +="\n" if format
          return result
        end
        result += ">"
        result += "\n" if format and @data==""
        result += @data if @data!=""
        @elements.each {|element| result+=element.to_xml(format, indent+4)}
        result += @xml if not @xml.nil?
        result += " "*indent if format and @data==""
        result+="</#{@tag}>"
        result+="\n" if format
        return result
      end

      ##
      # Climbs to the top of this elements parent tree and then returns
      # the to_xml XML string.
      #
      # return:: [String] The XML string of this element (from the topmost parent).
      #
      def to_s
        return @parent.to_s if @parent
        return to_xml(true)
      end
    end

    ##
    # This class is constructed from XML data elements that are received from
    # the Jabber service.
    #
    class ParsedXMLElement

      ##
      # This class is used to return nil element values to prevent errors (and
      # reduce the number of checks.
      #
      class NilParsedXMLElement

        ##
        # Override to return nil
        #
        # return:: [nil]
        #
        def method_missing(methId, *args)
          return nil
        end

        ##
        # Evaluate as nil
        #
        # return:: [Boolean] true
        #
        def nil?
          return true
        end

        ##
        # Return a zero count
        #
        # return:: [Integer] 0
        #
        def count
          0
        end

        include Singleton
      end

      # The <tag> as String
      attr_reader :element_tag

      # The parent ParsedXMLElement
      attr_reader :element_parent

      # A hash of ParsedXMLElement children
      attr_reader :element_children

      # The data <tag>data</tag> for a tag
      attr_reader :element_data

      ##
      # Construct an instance for the given tag
      #
      # tag:: [String] The tag
      # parent:: [Jabber::Protocol::ParsedXMLElement = nil] The parent element
      #
      def initialize(tag, parent=nil)
        @element_tag = tag
        @element_parent = parent
        @element_children = {}
        @attributes = {}
        @element_consumed = false
      end

      ##
      # Add the attribute to the element
      #   <tag name="value">data</tag>
      #
      # name:: [String] The attribute name
      # value:: [String] The attribute value
      # return:: [Jabber::Protocol::ParsedXMLElement] self for chaining
      #
      def add_attribute(name, value)
        @attributes[name]=value
        self
      end

      ##
      # Factory to build a child element from this element with the given tag
      #
      # tag:: [String] The tag name
      # return:: [Jabber::Protocol::ParsedXMLElement] The newly created child element
      #
      def add_child(tag)
        child = ParsedXMLElement.new(tag, self)
        @element_children[tag] = Array.new if not @element_children.has_key? tag
        @element_children[tag] << child
        return child
      end

      ##
      # When an xml is received from the Jabber service and a ParsedXMLElement is created,
      # it is propogated to all filters and listeners.  Any one of those can consume the element
      # to prevent its propogation to other filters or listeners. This method marks the element
      # as consumed.
      #
      def consume_element
        @element_consumed = true
      end

      ##
      # Checks if the element is consumed
      #
      # return:: [Boolean] True if the element is consumed
      #
      def element_consumed?
        @element_consumed
      end

      ##
      # Appends data to the element
      #
      # data:: [String] The data to append
      # return:: [Jabber::Protocol::ParsedXMLElement] self for chaining
      #
      def append_data(data)
        @element_data = "" unless @element_data
        @element_data += data
        self
      end

      ##
      # Calls the parent's element_children (hash) index off of this elements
      # tag and gets the supplied index.  In this sense it gets its sibling based
      # on offset.
      #
      # number:: [Integer] The number of the sibling to get
      # return:: [Jabber::Protocol::ParsedXMLElement] The sibling element
      #
      def [](number)
        return @element_parent.element_children[@element_tag][number] if @element_parent
      end

      ##
      # Returns the count of siblings with this element's tag
      #
      # return:: [Integer] The number of sibling elements
      #
      def count
        return @element_parent.element_children[@element_tag].size if @element_parent
        return 0
      end

      ##
      # see _count
      #
      def size
        count
      end

      ##
      # Overrides to allow for directly accessing child elements
      # and attributes.  If prefaced by attr_ it looks for an attribute
      # that matches or checks for a child with a tag that matches
      # the method name.  If no match occurs, it returns a
      # NilParsedXMLElement (singleton) instance.
      #
      # Example:: <alpha number="1"><beta number="2">Beta Data</beta></alpha>
      #
      #  element.element_tag #=> alpha
      #  element.attr_number #=> 1
      #  element.beta.element_data #=> Beta Data
      #
      def method_missing(methId, *args)
          tag = methId.id2name
          if tag[0..4]=="attr_"
            return @attributes[tag[5..-1]]
          end
          list = @element_children[tag]
          return list[0] if list
          return NilParsedXMLElement.instance
      end

      ##
      # Returns the valid XML as a string
      #
      # return:: [String] XML string
      def to_s
        begin
          result = "\n<#{@element_tag}"
          @attributes.each {|key, value| result += (' '+key+'="'+value+'"') }
          if @element_children.size>0 or @element_data
            result += ">"
          else
            result += "/>"
          end
          result += @element_data if @element_data
          @element_children.each_value {|array| array.each {|je| result += je.to_s} }
          result += "\n" if @element_children.size>0
          result += "</#{@element_tag}>" if @element_children.size>0 or @element_data
          result
        rescue => exception
          puts exception.to_s
        end
      end
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
          @started = false
          begin
            parser = REXML::Parsers::SAX2Parser.new @stream
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
          rescue REXML::ParseException
            @listener.parse_failure
          end
        end
      end
    end # USE_PARSER
  end
end


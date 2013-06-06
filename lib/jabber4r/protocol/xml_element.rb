# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber::Protocol
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
end
# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require 'base64'

module Jabber::Protocol::Authentication
  # Class provided SASL authentication on jabber server
  class SASL
    # Full list of mechanisms
    # http://www.iana.org/assignments/sasl-mechanisms/sasl-mechanisms.xhtml
    MECHANISMS = [:plain].freeze

    attr_reader :jid, :password
    attr_reader :mechanism

    # Public: Creates new SASL authentication object
    #
    # jid      - [Jabber::JID|String] the jid of jabber server user
    # password - String the user password
    # options  - Hash the authentication options (default: Empty hash)
    #            :mechanism - Symbol the name of mechnism to use
    #
    # Examples
    #
    # non_sasl = Jabber::Protocol::Authentication::SASL.new("strech@localhost/res-1", "my-pass-phrase")
    # non_sasl.plain? # => true
    # non_sasl.to_xml # =>
    #
    # <auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">biwsbj1qdWxpZXQscj1vTXNUQUF3QUFBQU1BQUFBTlAwVEFBQUFBQUJQVTBBQQ==</auth>
    def initialize(jid, password, options = {})
      raise TypeError,
        "Class(Jabber::JID) or Class(String) expected," +
        " but #{jid.class} was given" unless jid.is_a?(Jabber::JID) || jid.is_a?(String)

      @jid = jid.is_a?(Jabber::JID) ? jid : Jabber::JID.new(jid)
      @password = password

      @mechanism = options.fetch(:mechanism, :plain)

      raise ArgumentError,
        "Unknown authentication mechanism '#{mechanism}'," +
        " available is [#{MECHANISMS * ", "}]" unless MECHANISMS.include?(mechanism)
    end

    # Public: Is SASL object is for plain authentication
    #
    # Returns boolean
    def plain?
      mechanism == :plain
    end

    # Public: Create XML string from SASL object
    #
    # Returns String
    def dump
      Ox.dump(send mechanism)
    end
    alias :to_xml :dump

    # Public: Create Ox::Element from SASL object
    #
    # Returns Ox::Element
    def to_ox
      send(mechanism)
    end

    private
    # Internal: Make xml object for plain authentication mechanism
    #
    # Returns Ox:Element
    def plain
      Ox::Element.new("auth").tap do |element|
        element[:xmlns]     = "urn:ietf:params:xml:ns:xmpp-sasl"
        element[:mechanism] = "PLAIN"

        element << self.class.generate_plain(jid, password)
      end
    end

    def self.generate_plain(jid, password)
      ["#{jid.strip}\x00#{jid.node}\x00#{password}"].pack("m").gsub(/\s/, "")
    end
  end
end
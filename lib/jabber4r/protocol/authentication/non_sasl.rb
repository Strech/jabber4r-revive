# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require "digest/sha1"

module Jabber::Protocol::Authentication
  # Class provided Non-SASL authentication on jabber server
  # http://xmpp.org/extensions/xep-0078.html
  class NonSASL
    MECHANISMS = [:plain, :digest].freeze

    attr_reader :jid, :password
    attr_reader :stream_id, :mechanism

    # Public: Creates new Non-SASL authentication object
    #
    # jid      - [Jabber::JID|String] the jid of jabber server user
    # password - String the user password
    # options  - Hash the authentication options (default: Empty hash)
    #            :stream_id - String the stream identifier (authid)
    #            :mechanism - Symbol the name of mechnism to use
    #
    # Examples
    #
    # non_sasl = Jabber::Protocol::Authentication::NonSASL.new("strech@localhost/res-1", "my-pass-phrase")
    # non_sasl.plain? # => true
    # non_sasl.to_xml # =>
    #
    # <iq type="set" id="...">
    #   <query xmlns="jabber:iq:auth">
    #     <username>strech</username>
    #     <password>my-pass-phrase</password>
    #     <resource>res-1</resource>
    #   </query>
    # </iq>
    def initialize(jid, password, options = {})
      raise TypeError,
        "Class(Jabber::JID) or Class(String) expected," +
        " but #{jid.class} was given" unless jid.is_a?(Jabber::JID) || jid.is_a?(String)

      @jid = jid.is_a?(Jabber::JID) ? jid : Jabber::JID.new(jid)
      @password = password

      @mechanism = options.fetch(:mechanism, :plain)
      @stream_id = options.fetch(:stream_id) if digest?

      raise ArgumentError,
        "Unknown authentication mechanism '#{mechanism}'," +
        " available is [#{MECHANISMS * ", "}]" unless MECHANISMS.include?(mechanism)
    end

    # Public: Is NonSASL object is for plain authentication
    #
    # Returns boolean
    def plain?
      mechanism == :plain
    end

    # Public: Is NonSASL object is for digest authentication
    #
    # Returns boolean
    def digest?
      mechanism == :digest
    end

    # Public: Create XML string from NonSASL object
    #
    # Returns String
    def dump
      Ox.dump(send mechanism)
    end
    alias :to_xml :dump

    # Public: Create Ox::Element from NonSASL object
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
      query = Ox::Element.new("query").tap do |element|
        element[:xmlns] = "jabber:iq:auth"

        element << (Ox::Element.new("username") << jid.node)
        element << (Ox::Element.new("password") << password)
        element << (Ox::Element.new("resource") << jid.resource)
      end

      build_iq(query)
    end

    # Internal: Make xml object for digest authentication mechanism
    #
    # Returns Ox:Element
    def digest
      query = Ox::Element.new("query").tap do |element|
        element[:xmlns] = "jabber:iq:auth"

        digest_password = self.class.generate_digest(stream_id, password)

        element << (Ox::Element.new("username") << jid.node)
        element << (Ox::Element.new("digest")   << digest_password)
        element << (Ox::Element.new("resource") << jid.resource)
      end

      build_iq(query)
    end

    # Internal: The root iq stanza for authentication
    #
    # Returns Ox:Element
    def build_iq(query)
      Ox::Element.new("iq").tap do |element|
        element[:xmlns] = "jabber:client"
        element[:type]  = "set"
        element[:id]    = Jabber::Generators.id

        element << query
      end
    end

    # Internal: Generate hex string consist of concatination stream_id and password
    #
    # Returns String
    def self.generate_digest(stream_id, password)
      Digest::SHA1.hexdigest([stream_id, password].join)
    end
  end
end
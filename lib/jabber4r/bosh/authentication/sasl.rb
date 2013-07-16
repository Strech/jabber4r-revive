# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require "ox"

module Jabber::Bosh::Authentication
  # This class provides SASL authentication for BOSH session
  class SASL
    attr_reader :session
    attr_reader :mechanisms

    def initialize(session)
      @session = session
    end

    # Internal: Send open stream command to jabber server
    #
    # Raises XMLMalformedError
    # Returns boolean
    def open_stream
      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]         = "http://jabber.org/protocol/httpbind"
        element["xmlns:xmpp"]   = "urn:xmpp:xbosh"
        element["xmpp:version"] = "1.0"
        element[:content]       = "text/xml; charset=utf-8"
        element[:rid]           = session.request_id.next
        element[:to]            = session.domain
        element[:secure]        = true
        element[:wait]          = 60
        element[:hold]          = 1
      end

      Jabber.debug(%Q[Open (rid="#{body.rid}") new session])

      response = session.post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      define_stream_mechanisms(xml)

      raise Jabber::XMLMalformedError,
        "Couldn't find <body /> attribute [sid]" if xml[:sid].nil?

      session.sid = xml.sid

      true
    end

    # Internal: Send login request to jabber server
    #
    # password - String the password of jabber user
    #
    # Raises TypeError
    # Raises XMLMalformedError
    # Returns boolean
    def pass_authentication(password)
      # TODO : Define different exception type
      raise TypeError,
        "Server SASL mechanisms not include PLAIN mechanism" unless mechanisms.include?(:plain)

      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]         = 'http://jabber.org/protocol/httpbind'
        element["xmpp:version"] = "1.0"
        element["xmlns:xmpp"]   = "urn:xmpp:xbosh"
        element[:content]       = "text/xml; charset=utf-8"
        element[:rid]           = session.request_id.next
        element[:sid]           = session.sid

        element << Query.new(session.jid, password, mechanism: :plain).to_ox
      end

      Jabber.debug(%Q[Authenticate {SASL} (rid="#{body.rid}" sid="#{body.sid}") in opened session] +
                   %Q[ as #{session.jid}])

      response = session.post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      return false if xml.locate("success").empty?

      true
    end

    def restart_stream
      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]         = 'http://jabber.org/protocol/httpbind'
        element["xmlns:xmpp"]   = "urn:xmpp:xbosh"
        element["xmpp:version"] = "1.0"
        element["xmpp:restart"] = true
        element[:content]       = "text/xml; charset=utf-8"
        element[:rid]           = session.request_id.next
        element[:sid]           = session.sid
        element[:to]            = session.jid.domain
      end

      response = session.post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      return false if xml.locate("stream:features/bind").empty?

      true
    end

    def bind_resource
      bind = Ox::Element.new("bind").tap do |element|
        element[:xmlns] = "urn:ietf:params:xml:ns:xmpp-bind"

        element << (Ox::Element.new("resource") << session.jid.resource)
      end

      iq = Ox::Element.new("iq").tap do |element|
        element[:id]    = Jabber::Generators.id
        element[:type]  = "set"
        element[:xmlns] = "jabber:client"

        element << bind
      end

      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]         = 'http://jabber.org/protocol/httpbind'
        element["xmlns:xmpp"]   = "urn:xmpp:xbosh"
        element["xmpp:version"] = "1.0"
        element[:content]       = "text/xml; charset=utf-8"
        element[:rid]           = session.request_id.next
        element[:sid]           = session.sid

        element << iq
      end

      response = session.post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      raise Jabber::XMLMalformedError, "Couldn't find xml tag <iq/>" if xml.locate("iq").empty?
      return false unless xml.iq[:type] == "result"

      true
    end

    # TODO : Make state machine
    def authenticate(jid, password)
      open_stream

      return false if pass_authentication(password) == false
      return false if restart_stream == false

      bind_resource
    end

    # Public: ...
    #
    # xml - Ox::Element
    #
    # Returns Array[Symbol]
    def define_stream_mechanisms(xml)
      @mechanisms = xml.locate("stream:features/mechanisms/mechanism/*")
                       .map(&:downcase).map(&:to_sym)
    end

    private
    class Query
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
end
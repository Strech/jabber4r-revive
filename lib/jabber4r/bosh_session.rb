# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require "ox"
require "json"
require "net/http"
require "digest/sha1"

module Jabber
  # XMPP Over BOSH class
  # NOTE: http://xmpp.org/extensions/xep-0206.html
  class BoshSession
    # Public: Default connection options
    DEFAULTS = {
      host: "localhost",
      port: 5280,
      bind_uri: "/http-bind"
    }.freeze

    attr_reader :stream_id
    attr_reader :jid, :rid, :sid
    attr_reader :host, :port, :bind_uri

    # Public: Create new BOSH-session and bind it to jabber http-bind service
    #
    # username - String the login of jabber server user
    # password - String the password of jabber server user
    # options  - Hash the options for jabber http-bind service (default: Empty hash)
    #            :host     - String the jabber server host
    #            :port     - [String|Fixnum] the port of http-bind endpoint of jabber server
    #            :bind_uri - String the http-bind uri
    #
    #
    # Examples
    #
    # Jabber::BoshSession.bind("strech@localhost/res-1", "secret-pass")
    # Jabber::BoshSession.bind("strech@localhost/res-1", "secret-pass", )
    #
    # Raises Jabber::AuthenticationError
    # Returns Jabber::BoshSession
    def self.bind(username, password, options = {})
      host, port, bind_uri = DEFAULTS.dup.merge!(options).values

      session = new(host, port, bind_uri)
      raise AuthenticationError, "Failed to login" unless session.authenticate(username, password)

      session
    end

    # Public: Create new BOSH-session (not binded to http-bind service)
    #
    # host     - String the jabber server host
    # port     - [String|Fixnum] the port of http-bind endpoint of jabber server
    # bind_uri - String the http-bind uri
    #
    # Examples
    #
    # Jabber::BoshSession.new("localhost", 5280, "/http-bind")
    #
    # Returns Jabber::BoshSession
    def initialize(host, port, bind_uri)
      @host, @port, @bind_uri = host, port, bind_uri
      @alive = false
    end

    # Public: Authenticate user in jabber server by his username and password
    # NOTE: This authentication is Non-SASL http://xmpp.org/extensions/xep-0078.html
    #
    # Examples
    #
    # bosh = Jabber::BoshSession.new ...
    # bosh.authenticate("strech@localhost/my-resource", "super-secret-password") # => true
    # bosh.alive? # => true
    #
    # Returns boolean
    def authenticate(username, password)
      open_new_stream

      @jid = username.is_a?(JID) ? username : JID.new(username)
      @alive = login(jid, password)
    end

    # Public: Is BOSH-session active? (no polling consider)
    #
    # Returns boolean
    def alive?
      @alive
    end

    # Public: Represent BOSH-session as json object
    #
    # Returns String
    def to_json
      {jid: jid, rid: rid, sid: sid}.to_json
    end

    private
   # Internal: Send open stream command to jabber server
    #
    # Raises XMLMalformedError
    # Returns boolean
    def open_new_stream
      Jabber.debug("Open stream for bosh session")

      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]   = "http://jabber.org/protocol/httpbind"
        element[:content] = "text/xml; charset=utf-8"
        element[:rid]     = generate_next_rid
        element[:to]      = host
        element[:secure]  = true
        element[:wait]    = 60
        element[:hold]    = 1
      end

      response = post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      [:sid, :authid].each do |m|
        raise XMLMalformedError,
          "Couldn't find <body /> attribute [#{m}]" if xml[m].nil?
      end

      @sid, @stream_id = xml.sid, xml.authid

      true
    end

    # Internal: Send login request to jabber server
    #
    # jid - Jabber::JID the jid of jabber user
    # password - String the password of jabber user
    #
    # Raises ArgumentError
    # Raises XMLMalformedError
    # Returns boolean
    def login(jid, password)
      raise ArgumentError,
        "Jabber::JID expected, but #{jid.class} was given" unless jid.is_a?(JID)

      query = Ox::Element.new("query").tap do |element|
        element[:xmlns] = "jabber:iq:auth"

        element << (Ox::Element.new("username") << jid.node)
        element << (Ox::Element.new("digest")   << generate_digest_for(stream_id, password))
        element << (Ox::Element.new("resource") << jid.resource)
      end

      iq = Ox::Element.new("iq").tap do |element|
        element[:xmlns] = "jabber:client"
        element[:type]  = "set"
        element[:id]    = Jabber.gen_random_id

        element << query
      end

      body = Ox::Element.new("body").tap do |element|
        element[:xmlns]   = 'http://jabber.org/protocol/httpbind'
        element[:content] = "text/xml; charset=utf-8"
        element[:rid]     = generate_next_rid
        element[:sid]     = sid

        element << iq
      end

      response = post(Ox.dump body)
      xml = Ox.parse(response.body.tr("'", '"'))

      raise XMLMalformedError, "Couldn't find xml tag <iq/>" if xml.locate("iq").empty?
      return false unless xml.iq[:type] == "result"

      @rid = body.rid

      true
    end

    # Internal: Send HTTP-post request on HTTP-bind uri
    #
    # body - String data, which will be sended
    #
    # Examples
    #
    # post(%Q[<body><iq id="1"/></body>]) # => Net::HTTPSuccess
    #
    # Raises Net::HTTPBadResponse
    # Returns Net:HttpResponse
    def post(body)
      request = Net::HTTP::Post.new(bind_uri)
      request.body = body
      request.content_length = request.body.size
      request["Content-Type"] = "text/xml; charset=utf-8"

      Jabber.debug("Sending POST request - #{body.strip}")

      response = Net::HTTP.new(host, port).start { |http| http.request(request) }

      Jabber.debug("Receiving - #{response.code}: #{response.body.inspect}")

      unless response.is_a?(Net::HTTPSuccess)
        raise Net::HTTPBadResponse, "Net::HTTPSuccess expected, but #{response.class} was received"
      end

      response
    end

    # Internal: Generate hex string consist of concatination of all arguments
    #
    # Returns String
    def generate_digest_for(*args)
      Digest::SHA1.hexdigest(args.join)
    end

    # Internal: Generate next request id for http post request
    #
    # Returns Fixnum
    def generate_next_rid
      @rid ||= rand(1_000_000_000)
      @rid += 1
    end
  end
end
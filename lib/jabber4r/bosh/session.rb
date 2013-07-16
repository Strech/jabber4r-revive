# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

require "json"
require "net/http"

module Jabber::Bosh
  # This class provide XMPP Over BOSH
  # http://xmpp.org/extensions/xep-0206.html
  class Session
    # Public: Jabber user login
    attr_reader :jid
    # Public: Http request identifier
    attr_accessor :rid
    # Public: Session identifier
    attr_accessor :sid

    # Public: Bosh service domain
    # FIXME : Replace to host
    attr_reader :domain
    # Public: Bosh service port
    attr_reader :port
    # Public: Bosh service http-bind uri
    attr_reader :bind_uri

    # Public: Create new BOSH-session and bind it to jabber http-bind service
    #
    # username - String the login of jabber server user
    # password - String the password of jabber server user
    # options  - Hash the options for jabber http-bind service (default: Empty hash)
    #            :domain   - String the jabber server domain indentificator
    #            :port     - [String|Fixnum] the port of http-bind endpoint of jabber server
    #            :bind_uri - String the http-bind uri
    #            :use_sasl - boolean the flag defining authentication method
    #
    # Examples
    #
    # Jabber::Bosh::Session.bind("strech@localhost/res-1", "secret-pass")
    # Jabber::Bosh::Session.bind("strech@localhost/res-1", "secret-pass", domain: "localhost")
    #
    # Raises Jabber::AuthenticationError
    # Returns Jabber::Bosh::Session
    # TODO : Change arguments passing into initialize method
    def self.bind(username, password, options = {})
      domain, port, bind_uri, use_sasl = Jabber::Bosh::DEFAULTS.dup.merge!(options).values

      session = new(domain, port, bind_uri, use_sasl: use_sasl)
      raise Jabber::AuthenticationError, "Failed to login" unless session.authenticate(username, password)

      session
    end

    # Public: Create new BOSH-session (not binded to http-bind service)
    #
    # domain     - String the jabber server domain
    # port     - [String|Fixnum] the port of http-bind endpoint of jabber server
    # bind_uri - String the http-bind uri
    #
    # Returns Jabber::BoshSession
    def initialize(domain, port, bind_uri, options = {})
      @domain, @port, @bind_uri = domain, port, bind_uri
      @use_sasl = options.fetch(:use_sasl, Jabber::Bosh::DEFAULTS[:use_sasl])

      @alive = false
    end

    # Public: Authenticate user in jabber server by his username and password
    # NOTE: This authentication is SASL http://xmpp.org/rfcs/rfc3920.html#sasl
    # or Non-SASL http://xmpp.org/extensions/xep-0078.html
    #
    # Returns boolean
    def authenticate(username, password)
      @jid = username.is_a?(Jabber::JID) ? username : Jabber::JID.new(username)

      authentication = authentication_technology.new(self)
      @alive = authentication.authenticate(jid, password)
    end

    # Public: Is BOSH-session active? (no polling consider)
    #
    # Returns boolean
    def alive?
      @alive
    end

    # Public: Is BOSH-session uses sasl authentication
    #
    # Returns boolean
    def sasl?
      @use_sasl
    end

    # Public: Represent BOSH-session as json object
    #
    # Returns String
    def to_json
      {jid: jid.to_s, rid: rid.to_s, sid: sid}.to_json
    end

    # Internal: Send HTTP-post request on HTTP-bind uri
    #
    # body - String data, which will be sended
    #
    # Raises Net::HTTPBadResponse
    # Returns Net:HttpResponse
    def post(body)
      request = Net::HTTP::Post.new(bind_uri)
      request.body = body
      request.content_length = request.body.size
      request["Content-Type"] = "text/xml; charset=utf-8"

      Jabber.debug("Sending POST request - #{body.strip}")

      response = Net::HTTP.new(domain, port).start { |http| http.request(request) }

      Jabber.debug("Receiving POST response - #{response.code}: #{response.body.inspect}")

      unless response.is_a?(Net::HTTPSuccess)
        raise Net::HTTPBadResponse, "Net::HTTPSuccess expected, but #{response.class} was received"
      end

      response
    end

    # Internal: Generate request id object for http post request
    #
    # Returns Jabber::Generators::Rid
    def request_id
      @rid ||= Jabber::Generators.request
    end

    private
    def authentication_technology
      sasl? ? Jabber::Bosh::Authentication::SASL : Jabber::Bosh::Authentication::NonSASL
    end
  end
end

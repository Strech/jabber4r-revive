# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  # The Jabber ID class is used to hold a parsed jabber identifier (account+domain+resource)
  class JID
    PATTERN = /^(?:(?<node>[^@]*)@)??(?<domain>[^@\/]*)(?:\/(?<resource>.*?))?$/.freeze

    # Public: The node (account)
    attr_accessor :node

    # Public: The resource id
    attr_accessor :resource

    # Public: The domain indentificator (or IP address)
    attr_accessor :domain

    # Public: Convert something to Jabber::JID
    #
    # jid - [String|Jabber::JID] the jid of future Jabber::JID
    #
    # Returns Jabber::JID
    def self.to_jid(jid)
      return jid if jid.kind_of? self

      new jid
    end

    # Constructs a JID from the supplied string of the format:
    # node@domain[/resource] (e.g. "rich_kilmer@jabber.com/laptop")
    #
    # jid      - String the jabber id string to parse
    # domain     - String the domain of jabber server (optional)
    # resource - String the resource of jabber id (optional)
    #
    # Examples
    #
    # jid = Jabber::JID.new("strech@localhost/attach")
    # jid.node # => "strech"
    # jid.domain # => "localhost"
    # jid.resource # => "attach"
    #
    # Raises ArgumentError
    # Returns nothing
    def initialize(jid, domain = nil, resource = nil)
      raise ArgumentError, "Node can't be empty" if jid.to_s.empty?

      @node, @domain, @resource = self.class.parse(jid)
      @node, @domain = @domain, nil if @node.nil? && @domain

      @domain = domain unless domain.nil?
      @resource = resource unless resource.nil?

      raise ArgumentError, "Couldn't create JID without domain" if @domain.to_s.empty?
    end

    # Public: Evalutes whether the node, resource and domain are the same
    #
    # jid - Jabber::JID the other jabber id
    #
    # Returns boolean
    def ==(jid)
      jid.to_s == self.to_s
    end

    # Public: Compare accounts without resources
    #
    # jid - Jabber::JID the other jabber id
    #
    # Returns boolean
    def same?(jid)
      other_jid = self.class.to_jid(jid)

      other_jid.node == node && other_jid.domain == domain
    end

    # Public: Strip resource from jid and return new object
    #
    # Returns Jabber::JID
    def strip
      self.class.new(node, domain)
    end

    # Public: Strip resource from jid and return the same object
    #
    # Returns Jabber::JID
    def strip!
      @resource = nil

      self
    end

    # Public: String representation of JID
    #
    # Returns String
    def to_s
      ["#{node}@#{domain}", resource].compact.join "/"
    end

    # Public: Override #hash to hash based on the to_s method
    #
    # Returns Fixnum
    def hash
      to_s.hash
    end

    private
    # Internal: Parse jid string for node, domain, resource
    #
    # jid - String jabber id
    #
    # Examples
    #
    # result = Jabber::JID.parse("strech@localhost/pewsource")
    # result # => ["strech", "localhost", "pewsource"]
    #
    # Rerturns Array
    def self.parse(jid)
      jid.match(PATTERN).captures
    end
  end
end

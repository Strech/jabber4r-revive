# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber
  # The Jabber ID class is used to hold a parsed jabber identifier (account+host+resource)
  class JID
    PATTERN = /^(?:(?<node>[^@]*)@)??(?<host>[^@\/]*)(?:\/(?<resource>.*?))?$/.freeze

    # The node (account)
    attr_accessor :node

    # The resource id
    attr_accessor :resource

    # The host name (or IP address)
    attr_accessor :host

    def JID.to_jid(id)
      return id if id.kind_of? JID
      return JID.new(id)
    end

    # Constructs a JID from the supplied string of the format:
    # node@host[/resource] (e.g. "rich_kilmer@jabber.com/laptop")
    #
    # jid      - String the jabber id string to parse
    # host     - String the host of jabber server (optional)
    # resource - String the resource of jabber id (optional)
    #
    # Examples
    #
    # jid = Jabber::JID.new("strech@localhost/attach")
    # jid.node # => "strech"
    # jid.host # => "localhost"
    # jid.resource # => "attach"
    #
    # Raises ArgumentError
    # Returns nothing
    def initialize(jid, host = nil, resource = nil)
      raise ArgumentError, "Node can't be empty" if jid.to_s.empty?

      @node, @host, @resource = self.class.parse(jid)
      @node, @host = @host, nil if @node.nil? && @host

      @host = host unless host.nil?
      @resource = resource unless resource.nil?

      raise ArgumentError, "Couldn't create JID without host" if @host.to_s.empty?
    end

    # Public: Evalutes whether the node, resource and host are the same
    #
    # jid - Jabber::JID the other jabber id
    #
    # Returns boolean
    def ==(jid)
      jid.to_s == self.to_s
    end

    def same_account?(other)
      other = JID.to_jid(other)
      return true if other.node==@node  and other.host==@host
       return false
    end

    # Public: Strip resource from jid and return new object
    #
    # Returns Jabber::JID
    def strip
      self.class.new(node, host)
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
      ["#{node}@#{host}", resource].compact.join "/"
    end

    # Public: Override #hash to hash based on the to_s method
    #
    # Returns Fixnum
    def hash
      to_s.hash
    end

    private
    # Internal: Parse jid string for node, host, resource
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

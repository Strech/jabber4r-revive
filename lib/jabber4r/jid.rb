# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
module Jabber
  # The Jabber ID class is used to hold a parsed jabber identifier (account+host+resource)
  class JID
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

      @host = host unless host.nil?
      @resource = resource unless resource.nil?
    end

    ##
    # Evalutes whether the node, resource and host are the same
    #
    # other:: [Jabber::JID] The other jabber id
    # return:: [Boolean] True if they match
    def ==(other)
      return true if other.node==@node and other.resource==@resource and other.host==@host
      return false
    end

    def same_account?(other)
      other = JID.to_jid(other)
      return true if other.node==@node  and other.host==@host
       return false
    end

    ##
    # Removes the resource from this JID
    #
    def strip_resource
      @resource=nil
      return self
    end

    ##
    # Returns the string ("node@host/resource") representation of this JID
    #
    # return:: [String] String form of JID
    #
    def to_s
      result = (@node.to_s+"@"+@host.to_s)
      result += ("/"+@resource) if @resource
      return result
    end

    ##
    # Override #hash to hash based on the to_s method
    #
    def hash
      return to_s.hash
    end

    # Public: Возвращает JID у которого отсутствует ресурс
    # TODO: Будет перенесено в гем
    #
    # Returns XMPP::JID
    def strip
      JID.new(@node, @host)
    end

    private
    # Internal: Parse jid string for node, host, resource
    #
    # jid - String jabber id
    #
    # Examples
    #
    # Jabber::JID.parse("strech@localhost/pewsource") # => ["strech", "localhost", "pewsource"]
    #
    # Rerturns Array
    def self.parse(jid)
      at_loc    = jid.index("@")
      slash_loc = jid.index("/")

      node = jid.dup
      host = nil
      resource = slash_loc.nil? ? nil : jid[slash_loc + 1, node.length]

      if at_loc
        node = jid[0, at_loc]

        host_end = slash_loc.nil? ? jid.length - (at_loc + 1) : slash_loc - (at_loc + 1)
        host = jid[at_loc + 1, host_end]
      elsif slash_loc
        node = jid[0, slash_loc]
      end

      [node, host, resource]
    end
  end
end

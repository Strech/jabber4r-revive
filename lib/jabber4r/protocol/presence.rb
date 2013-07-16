# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber::Protocol
  ##
  # The presence class is used to construct presence messages to
  # send to the Jabber service.
  #
  class Presence
    attr_accessor :to, :from, :id, :type

    # The state to show (chat, xa, dnd, away)
    attr_accessor :show

    # The status message
    attr_accessor :status
    attr_accessor :priority

    ##
    # Constructs a Presence object w/the supplied id
    #
    # id:: [String] The message ID
    # show:: [String] The state to show
    # status:: [String] The status message
    #
    def initialize(id, show=nil, status=nil)
      @id = id
      @show = show if show
      @status = status if status
    end

    ##
    # Generate a presence object for initial presence notification
    #
    # id:: [String] The message ID
    # show:: [String] The state to show
    # status:: [String] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_initial(id, show=nil, status=nil)
      Presence.new(id, show, status)
    end

    ##
    # Generate a presence object w/show="normal" (normal availability)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_normal(id, status=nil)
      Presence.new(id, "normal", status)
    end

    ##
    # Generate a presence object w/show="chat" (free for chat)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_chat(id, status=nil)
      Presence.new(id, "chat", status)
    end

    ##
    # Generate a presence object w/show="xa" (extended away)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_xa(id, status=nil)
      Presence.new(id, "xa", status)
    end

    ##
    # Generate a presence object w/show="dnd" (do not disturb)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_dnd(id, status=nil)
      Presence.new(id, "dnd", status)
    end

    ##
    # Generate a presence object w/show="away" (away from resource)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_away(id, status=nil)
      Presence.new(id, "away", status)
    end

    ##
    # Generate a presence object w/show="unavailable" (not free for chat)
    #
    # id:: [String] The message ID
    # status:: [String=nil] The status message
    # return:: [Jabber::Protocol::Presence] The newly created Presence object
    #
    def self.gen_unavailable(id, status=nil)
      p = Presence.new(id)
      p.type="unavailable"
      p
    end

    def self.gen_new_subscription(to)
      p = Presence.new(Jabber::Generators.id)
      p.type = "subscribe"
      p.to = to
      p
    end

    def self.gen_accept_subscription(id, jid)
      p = Presence.new(id)
      p.type = "subscribed"
      p.to = jid
      p
    end

    def self.gen_accept_unsubscription(id, jid)
      p = Presence.new(id)
      p.type = "unsubscribed"
      p.to = jid
      p
    end

    ##
    # Generates the xml representation of this Presence object
    #
    # return:: [String] The presence XML message to send the Jabber service
    #
    def to_xml
      e = XMLElement.new("presence")
      e.add_attribute("id", @id) if @id
      e.add_attribute("from", @from) if @from
      e.add_attribute("to", @to) if @to
      e.add_attribute("type", @type) if @type
      e.add_child("show").add_data(@show) if @show
      e.add_child("status").add_data(@status) if @status
      e.add_child("priority") if @priority
      e.to_s
    end

    ##
    # see _to_xml
    #
    def to_s
      to_xml
    end
  end
end

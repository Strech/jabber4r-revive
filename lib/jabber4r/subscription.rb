# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  class Subscription
    attr_accessor :type, :from, :id, :session
    def initialize(session, type, from, id)
      @session = session
      @type = type
      @from = from
      @id = id
    end
    def accept
      case type
      when :subscribe
        @session.connection.send(Jabber::Protocol::Presence.gen_accept_subscription(@id, @from))
      when :unsubscribe
        @session.connection.send(Jabber::Protocol::Presence.gen_accept_unsubscription(@id, @from))
      else
        raise "Cannot accept a subscription of type #{type.to_s}"
      end
    end
  end
end
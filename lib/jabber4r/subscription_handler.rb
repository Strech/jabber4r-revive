# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  ##
  # This is a base class for subscription handlers

  class SubscriptionHandler
    def subscribe(subscription)
    end

    def subscribed(subscription)
    end

    def unsubscribe(subscription)
    end

    def unsubscribed(subscription)
    end
  end
end
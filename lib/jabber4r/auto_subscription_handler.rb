# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  class AutoSubscriptionHandler < SubscriptionHandler

    def subscribe(subscription)
      subscription.accept
    end

    def unsubscribe(subscription)
      subscription.accept
    end
  end
end
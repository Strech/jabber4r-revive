# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber::Protocol
  # Public: This module provide authentication methods for xmpp protocol
  module Authentication; end
end

require "jabber4r/protocol/authentication/non_sasl"
require "jabber4r/protocol/authentication/sasl"
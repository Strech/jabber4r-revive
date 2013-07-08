# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber::Bosh
  module Authentication; end
end

require "jabber4r/bosh/authentication/sasl"
require "jabber4r/bosh/authentication/non_sasl"

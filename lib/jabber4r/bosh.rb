# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
# Copyright (C) 2013  Sergey Fedorov <strech_ftf@mail.ru>

module Jabber
  module Bosh
    # Public: Default connection options
    DEFAULTS = {
      domain: "localhost",
      port: 5280,
      bind_uri: "/http-bind",
      use_sasl: true
    }.freeze
  end
end

require "jabber4r/bosh/authentication"
require "jabber4r/bosh/session"
# License: see LICENSE.txt
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>


# The Jabber module is the main namespace for all Jabber modules
# and classes.
module Jabber
  DEBUG = false

  # Public: Should raise if connection was force closed
  class ConnectionForceCloseError < StandardError; end

  # Public: Should raise if received XML data is malformed
  class XMLMalformedError < StandardError; end

  # Public: Should raise if authentication failed
  class AuthenticationError < StandardError; end
end

require "jabber4r/debugger"
require "jabber4r/session"
require "jabber4r/bosh_session"
require "jabber4r/protocol"
require "jabber4r/connection"
require "jabber4r/protocol/iq"
require "jabber4r/protocol/presence"
require "jabber4r/protocol/message"
require "jabber4r/protocol/xml_element"
require "jabber4r/protocol/parsed_xml_element"
require "jabber4r/roster"
require "jabber4r/jid"
require "jabber4r/vcard"

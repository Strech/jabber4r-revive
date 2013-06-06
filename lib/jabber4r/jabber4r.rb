# License: see LICENSE.txt
#  Jabber4R - Jabber Instant Messaging Library for Ruby
#  Copyright (C) 2002  Rich Kilmer <rich@infoether.com>
#

##
# The Jabber module is the main namespace for all Jabber modules
# and classes.
#
module Jabber
  DEBUG = false
end

require "jabber4r/session"
require "jabber4r/protocol"
require "jabber4r/protocol/connection"
require "jabber4r/protocol/iq"
require "jabber4r/protocol/presence"
require "jabber4r/protocol/message"
require "jabber4r/roster"
require "jabber4r/jid"
require "jabber4r/vcard"

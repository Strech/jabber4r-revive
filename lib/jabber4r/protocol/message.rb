# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber::Protocol
  class Message
    attr_accessor :to, :from, :id, :type, :body, :xhtml, :subject, :thread, :x, :oobData, :errorcode, :error
    NORMAL = "normal"
    ERROR="error"
    CHAT="chat"
    GROUPCHAT="groupchat"
    HEADLINE="headline"

    ##
    # Factory to build a Message from an XMLElement
    #
    # session:: [Jabber::Session] The Jabber session instance
    # element:: [Jabber::Protocol::ParsedXMLElement] The received XML object
    # return:: [Jabber::Protocol::Message] The newly created Message object
    #
    def self.from_element(session, element)
      message = Message.new(element.attr_to)
      message.from = Jabber::JID.new(element.attr_from) if element.attr_from
      message.type = element.attr_type
      message.id = element.attr_id
      message.thread = element.thread.element_data
      message.body = element.body.element_data
      message.xhtml = element.xhtml.element_data
      message.subject = element.subject.element_data
      message.oobData = element.x.element_data
      message.session=session
      return message
    end

    ##
    # Creates a Message
    #
    # to:: [String | Jabber::JID] The jabber id to send this message to (or from)
    # type:: [Integer=NORMAL] The type of message...Message::(NORMAL, CHAT, GROUPCHAT, HEADLINE)
    #
    def initialize(to, type=NORMAL)
      return unless to
      to = Jabber::JID.new(to) if to.kind_of? String
      @to = to if to.kind_of? Jabber::JID
      @type = type
    end

    ##
    # Chaining method...sets the body of the message
    #
    # body:: [String] The message body
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def set_body(body)
      @body = body.gsub(/[&]/, '&amp;').gsub(/[<]/, '&lt;').gsub(/[']/, '&apos;')
      self
    end

    ##
    # Chaining method...sets the subject of the message
    #
    # subject:: [String] The message subject
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def set_subject(subject)
      @subject = subject.gsub(/[&]/, '&amp;').gsub(/[<]/, '&lt;').gsub(/[']/, '&apos;')
      self
    end

    ##
    # Chaining method...sets the XHTML body of the message
    #
    # body:: [String] The message body
    # return:: [Jabber::Protocol::Message] The current message object
    #
    def set_xhtml(xhtml)
      @xhtml=xhtml
      self
    end

    ##
    # Chaining method...sets the thread of the message
    #
    # thread:: [String] The message thread id
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def set_thread(thread)
      @thread = thread
      self
    end

    ##
    # Chaining method...sets the OOB data of the message
    #
    # data:: [String] The message OOB data
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def set_outofband(data)
      @oobData = data
      self
    end

    ##
    # Chaining method...sets the extended data of the message
    #
    # x:: [String] The message x data
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def set_x(x)
      @x = x
      self
    end

    ##
    # Sets an error code to be returned(chaining method)
    #
    # code:: [Integer] the jabber error code
    # reason:: [String] Why the error was reported
    # return:: [Jabber::Protocol::Message] The current Message object
    #

    def set_error(code,reason)
     @errorcode=code
     @error=reason
     @type="error"
     self
    end

    ##
    # Convenience method for send(true)
    #
    # ttl:: [Integer = nil] The time (in seconds) to wait for a reply before assuming nil
    # &block:: [Block] A block to process the message replies
    #
    def request(ttl=nil, &block)
      send(true, ttl, &block)
    end

    ##
    # Sends the message to the Jabber service for delivery
    #
    # wait:: [Boolean = false] Wait for reply before return?
    # ttl:: [Integer = nil] The time (in seconds) to wait for a reply before assuming nil
    # &block:: [Block] A block to process the message replies
    #
    def send(wait=false, ttl=nil, &block)
      if wait
        message = nil
        blockedThread = Thread.current
        timer_thread = nil
        timeout = false
        unless ttl.nil?
          timer_thread = Thread.new {
            sleep ttl
            timeout = true
            blockedThread.wakeup
          }
        end
        @session.connection.send(self.to_s, block) do |je|
          if je.element_tag == "message" and je.thread.element_data == @thread
            je.consume_element
            message = Message.from_element(@session, je)
            blockedThread.wakeup unless timeout
            unless timer_thread.nil?
              timer_thread.kill
              timer_thread = nil
            end
          end
        end
        Thread.stop
        return message
      else
        @session.connection.send(self.to_s, block) if @session
      end
    end

    ##
    # Sets the session instance
    #
    # session:: [Jabber::Session] The session instance
    # return:: [Jabber::Protocol::Message] The current Message object
    #
    def session=(session)
      @session = session
      self
    end

    ##
    # Builds a reply to an existing message by setting:
    # 1. to = from
    # 2. id = id
    # 3. thread = thread
    # 4. type = type
    # 5. session = session
    #
    # return:: [Jabber::Protocol::Message] The reply message
    #
    def reply
      message = Message.new(nil)
      message.to = @from
      message.id = @id
      message.thread = @thread
      message.type = @type
      message.session = @session
      @is_reply = true
      return message
    end

    ##
    # Generates XML that complies with the Jabber protocol for
    # sending the message through the Jabber service.
    #
    # return:: [String] The XML string.
    #
    def to_xml
      @thread = Jabber.gen_random_thread if @thread.nil? and (not @is_reply)
      elem = XMLElement.new("message", {"to"=>@to, "type"=>@type})
      elem.add_attribute("id", @id) if @id
      elem.add_child("thread").add_data(@thread) if @thread
      elem.add_child("subject").add_data(@subject) if @subject
      elem.add_child("body").add_data(@body) if @body
      if @xhtml then
        t=elem.add_child("xhtml").add_attribute("xmlns","http://www.w3.org/1999/xhtml")
        t.add_child("body").add_data(@xhtml)
      end
      if @type=="error" then
        e=elem.add_child("error");
        e.add_attribute("code",@errorcode) if @errorcode
        e.add_data(@error) if @error
      end
      elem.add_child("x").add_attribute("xmlns", "jabber:x:oob").add_data(@oobData) if @oobData
      elem.add_xml(@x.to_s) if @x
      return elem.to_s
    end

    ##
    # see to_xml
    #
    def to_s
      to_xml
    end

  end
end
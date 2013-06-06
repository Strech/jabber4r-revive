# coding: utf-8

# License: see LICENSE
# Jabber4R - Jabber Instant Messaging Library for Ruby
# Copyright (C) 2002  Rich Kilmer <rich@infoether.com>

module Jabber::Protocol
  ##
  # A class used to build/parse IQ requests/responses
  #
  class Iq
    attr_accessor :session,:to, :from, :id, :type, :xmlns, :data,:error,:errorcode
    ERROR="error"
    GET="get"
    SET="set"
    RESULT="result"

    ##
    # Factory to build an IQ object from xml element
    #
    # session:: [Jabber::Session] The Jabber session instance
    # element:: [Jabber::Protocol::ParsedXMLElement] The received XML object
    # return:: [Jabber::Protocol::Iq] The newly created Iq object
    #
    def self.from_element(session, element)
      iq = new(session)

      iq.from = Jabber::JID.new(element.attr_from) if element.attr_from
      iq.to   = Jabber::JID.new(element.attr_to) if element.attr_to

      iq.id = element.attr_id
      iq.type = element.attr_type
      iq.xmlns = element.query.attr_xmlns
      iq.data  = element.query
      iq.session = session

      if element.attr_type = "error"
        iq.error = element.error
        iq.errorcode = element.error.attr_code
      end

      return iq
    end

    ##
    # Default constructor to build an Iq object
    # session:: [Jabber::Session] The Jabber session instance
    # id:: [String=nil] The (optional) id of the Iq object
    def initialize(session,id=nil)
      @session=session
      @id=id
    end

    ##
    # Return an IQ object that uses the jabber:iq:private namespace
    #
    def self.get_private(session,id,ename,ns)
      iq=Iq.new(session,id)
      iq.type="get"
      iq.xmlns="jabber:iq:private"
      iq.data=XMLElement.new(ename,{'xmlns' => ns});
      return iq
    end


    ##
    # Generates an IQ roster request XML element
    #
    # id:: [String] The message id
    # return:: [String] The XML data to send
    #
    def self.gen_roster(session, id)
      iq = Iq.new(session, id)
      iq.type = "get"
      iq.xmlns = "jabber:iq:roster"
      return iq
      #return XMLElement.new("iq", {"type"=>"get", "id"=>id}).add_child("query", {"xmlns"=>"jabber:iq:roster"}).to_s
    end

    ##
    # Generates an IQ authortization request XML element
    #
    # id:: [String] The message id
    # username:: [String] The username
    # password:: [String] The password
    # email:: [String] The email address of the account
    # name:: [String] The full name
    # return:: [String] The XML data to send
    #
    def self.gen_registration(session, id, username, password, email, name)
      iq = Iq.new(session, id)
      iq.type = "set"
      iq.xmlns = "jabber:iq:register"
      iq.data = XMLElement.new("username").add_data(username).to_s
      iq.data << XMLElement.new("password").add_data(password).to_s
      iq.data << XMLElement.new("email").add_data(email).to_s
      iq.data << XMLElement.new("name").add_data(name).to_s
      return iq
    end

    ##
    # Generates an IQ Roster Item add request XML element
    #
    # session:: [Session] The session
    # id:: [String] The message id
    # jid:: [JID] The Jabber ID to add to the roster
    # name:: [String] The full name
    # return:: [String] The XML data to send
    #
    def self.gen_add_rosteritem(session, id, jid, name)
      iq = Iq.new(session, id)
      iq.type = "set"
      iq.xmlns = "jabber:iq:roster"
      iq.data = XMLElement.new("item").add_attribute("jid", jid).add_attribute("name", name).to_s
      return iq
    end

    ##
    # Generates an IQ authortization request XML element
    #
    # id:: [String] The message id
    # username:: [String] The username
    # password:: [String] The password
    # resource:: [String] The resource to bind this session to
    # return:: [String] The XML data to send
    #
    def self.gen_auth(session, id, username, password, resource)
      iq = Iq.new(session, id)
      iq.type = "set"
      iq.xmlns = "jabber:iq:auth"
      iq.data = XMLElement.new("username").add_data(username).to_s
      iq.data << XMLElement.new("password").add_data(password).to_s
      iq.data << XMLElement.new("resource").add_data(resource).to_s
      return iq
      #element = XMLElement.new("iq", {"type"=>"set", "id"=>id}).add_child("query", {"xmlns"=>"jabber:iq:auth"}).add_child("username").add_data(username).to_parent.add_child("password").add_data(password).to_parent.add_child("resource").add_data(resource).to_parent.to_s
    end

    ##
    # Generates an IQ digest authortization request XML element
    #
    # id:: [String] The message id
    # username:: [String] The username
    # digest:: [String] The SHA-1 hash of the sessionid and the password
    # resource:: [String] The resource to bind this session to
    # return:: [String] The XML data to send
    #
    def self.gen_auth_digest(session, id, username, digest, resource)
      iq = Iq.new(session, id)
      iq.type = "set"
      iq.xmlns = "jabber:iq:auth"
      iq.data = XMLElement.new("username").add_data(username).to_s
      iq.data << XMLElement.new("digest").add_data(digest).to_s
      iq.data << XMLElement.new("resource").add_data(resource).to_s
      return iq
      #return XMLElement.new("iq", {"type"=>"set", "id"=>id}).add_child("query", {"xmlns"=>"jabber:iq:auth"}).add_child("username").add_data(username).to_parent.add_child("digest").add_data(digest).to_parent.add_child("resource").add_data(resource).to_parent.to_s
    end

    ##
    # Generates an IQ out of bounds XML element
    #
    # to:: [JID] The Jabber ID to send to
    # url:: [String] The data to send
    # desc:: [String=""] The description of the data
    # return:: [String] The XML data to send
    #
    def self.gen_oob(session, to, url, desc="")
      iq = Iq.new(session, nil)
      iq.type = "set"
      iq.xmlns = "jabber:iq:oob"
      iq.data = XMLElement.new("url").add_data(url).to_s
      iq.data << XMLElement.new("desc").add_data(desc).to_s
      return iq
      #return XMLElement.new("iq", {"type"=>"set"}).add_child("query", {"xmlns"=>"jabber:iq:oob"}).add_child("url").add_data(url).to_parent.add_child("desc").add_data(data).to_parent.to_s
    end

    ##
    # Generates an VCard request XML element
    #
    # id:: [String] The message ID
    # to:: [JID] The jabber id of the account to get the VCard for
    # return:: [String] The XML data to send
    #
    def self.gen_vcard(session, id, to)
      iq = Iq.new(session, id)
      iq.xmlns = "vcard-temp"
      iq.type = "get"
      iq.to = to
      return iq
      #return XMLElement.new("iq", {"type"=>"get", "id"=>id, "to"=>to}).add_child("query", {"xmlns"=>"vcard-temp"}).to_s
    end




    ##
    # Sends the IQ to the Jabber service for delivery
    #
    # wait:: [Boolean = false] Wait for reply before return?
    # &block:: [Block] A block to process the message replies
    #
    def send(wait=false, &block)
      if wait
        iq = nil
        blockedThread = Thread.current
        @session.connection.send(self.to_s, block) do |je|
          if je.element_tag == "iq" and je.attr_id == @id
            je.consume_element
            iq = self.class.from_element(@session, je)
            blockedThread.wakeup
          end
        end
        Thread.stop
        return iq
      else
        @session.connection.send(self.to_s, block) if @session
      end
    end

    ##
    # Builds a reply to an existing Iq
    #
    # return:: [Jabber::Protocol::Iq] The result Iq
    #
    def reply
      iq = Iq.new(@session,@id)
      iq.to = @from
      iq.id = @id
      iq.type = 'result'
      @is_reply = true
      return iq
    end

    ##
    # Generates XML that complies with the Jabber protocol for
    # sending the Iq through the Jabber service.
    #
    # return:: [String] The XML string.
    #
    def to_xml
      elem = XMLElement.new("iq", { "type"=>@type})
      elem.add_attribute("to" ,@to) if @to
      elem.add_attribute("id", @id) if @id
      elem.add_child("query").add_attribute("xmlns",@xmlns).add_data(@data.to_s)
      if @type=="error" then
        e=elem.add_child("error");
        e.add_attribute("code",@errorcode) if @errorcode
        e.add_data(@error) if @error
      end
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
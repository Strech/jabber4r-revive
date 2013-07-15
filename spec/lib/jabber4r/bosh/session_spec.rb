# coding: utf-8
require "spec_helper"

describe Jabber::Bosh::Session do
  let(:rid) { double "Rid" }

  before do
    rid.stub(:next).and_return(2,3,4,5)
    rid.stub(:to_s).and_return "3"

    Jabber::Generators.stub(:request).and_return rid
  end

  describe "#bind" do
    context "when server accept sasl authentication" do
      let(:bosh_session) { described_class.bind("strech@localhost/resource", "password") }

      let(:successful_login) { '<body xmlns="http://jabber.org/protocol/httpbind"><success xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/></body>' }
      let(:successful_open_stream) do
        [
          '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:xmpp="urn:xmpp:xbosh" xmlns:stream="http://etherx.jabber.org/streams"' +
          'charsets="UTF-8" from="localhost" hold="1" inactivity="20" polling="5" requests="2" sid="67d63e06-4159-43e2-9cb8-544de83eae58"' +
          'ver="1.6" wait="60" xmpp:version="1.0"><stream:features><mechanisms xmlns="urn:ietf:params:xml:ns:xmpp-sasl"><mechanism>PLAIN</mechanism>' +
          '</mechanisms></stream:features></body>'
        ].join " "
      end
      let(:successful_restart) do
        [
          '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:stream="http://etherx.jabber.org/streams">' +
          '<stream:features><bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"/></stream:features></body>'
        ].join " "
      end
      let(:successful_bind) do
        [
          '<body xmlns="http://jabber.org/protocol/httpbind"><iq id="Jabber4R_f7e7fc2a10013070" type="result">' +
          '<bind xmlns="urn:ietf:params:xml:ns:xmpp-bind"><jid>strech@localhost/resource</jid></bind></iq></body>'
        ].join " "
      end

      let(:is_open_stream?) { ->(data) { x = Ox.parse(data); "2" == x[:rid] } }
      let(:is_login?) { ->(data) { x = Ox.parse(data); "3" == x[:rid] && !x.locate("auth").empty? } }
      let(:is_restart?) { ->(data) { x = Ox.parse(data); "4" == x[:rid] && x["xmpp:restart"] = "true" } }
      let(:is_bind?) { ->(data) { x = Ox.parse(data); "5" == x[:rid] && !x.locate("iq/bind").empty? } }

      context "when session successfuly binded" do
        before do
          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_open_stream?)
            .to_return(body: successful_open_stream)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_login?)
            .to_return(body: successful_login)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)
            .to_return(body: successful_restart)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_bind?)
            .to_return(body: successful_bind)
        end

        it { expect(bosh_session).to be_alive }
      end

      context "when couldn't open stream" do
        context "when response body missed sid attribute" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:xmpp="urn:xmpp:xbosh" xmlns:stream="http://etherx.jabber.org/streams"/>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: malformed_body)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
          end

          it { expect { bosh_session }.to raise_error Jabber::XMLMalformedError, "Couldn't find <body /> attribute [sid]" }
        end

        context "when response was not 200 OK" do
          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: "Foo", status: 401)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
          end

          it { expect { bosh_session }.to raise_error Net::HTTPBadResponse }
        end
      end

      context "when couldn't login in opened stream" do
        context "when response has no auth mechanisms" do
          let(:malformed_body) do
            [
              '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:xmpp="urn:xmpp:xbosh" xmlns:stream="http://etherx.jabber.org/streams"' +
              'charsets="UTF-8" from="localhost" hold="1" inactivity="20" polling="5" requests="2" sid="67d63e06-4159-43e2-9cb8-544de83eae58"' +
              'ver="1.6" wait="60" xmpp:version="1.0"/>'
            ].join " "
          end

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: malformed_body)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_login?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
          end

          it { expect { bosh_session }.to raise_error TypeError, "Server SASL mechanisms not include PLAIN mechanism" }
        end

        context "when response has type not equal 'success'" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind"><error xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/></body>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: malformed_body)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
          end

          it { expect { bosh_session }.to raise_error Jabber::AuthenticationError, "Failed to login" }
        end

        context "when response was not 200 OK" do
          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: "Foo", status: 401)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
          end

          it { expect { bosh_session }.to raise_error Net::HTTPBadResponse }
        end
      end

      context "when cann't restart opened stream" do
        let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:stream="http://etherx.jabber.org/streams"><error xmlns="urn:ietf:params:xml:ns:xmpp-sasl"/></body>' }

        before do
          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_open_stream?)
            .to_return(body: successful_open_stream)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_login?)
            .to_return(body: successful_login)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_restart?)
            .to_return(body: malformed_body)

          WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
            .with(body: is_bind?)
        end

        it { expect { bosh_session }.to raise_error Jabber::AuthenticationError, "Failed to login" }
      end

      context "when cann't bind resource on opened stream" do
        context "when response is a malformed xml without IQ tag" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind"></body>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: successful_login)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_restart?)
              .to_return(body: successful_restart)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
              .to_return(body: malformed_body)
          end

          it { expect { bosh_session }.to raise_error Jabber::XMLMalformedError, "Couldn't find xml tag <iq/>" }
        end

        context "when response has type not equal 'result'" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind"><iq id="Jabber4R_f7e7fc2a10013070" type="error"/></body>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: successful_login)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_restart?)
              .to_return(body: successful_restart)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_bind?)
              .to_return(body: malformed_body)
          end

          it { expect { bosh_session }.to raise_error Jabber::AuthenticationError, "Failed to login" }
        end
      end
    end

    # REFACTOR ALL

    context "when server accept non-sasl authentication" do
      let(:bosh_session) { described_class.bind("strech@localhost/resource", "password", use_sasl: false) }

      let(:successful_login) { '<body xmlns="http://jabber.org/protocol/httpbind"><iq type="result" xmlns="jabber:client" id="2034"/></body>' }
      let(:successful_open_stream) do
        [
          '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:xmpp="urn:xmpp:xbosh" xmlns:stream="http://etherx.jabber.org/streams"',
          'authid="3780309894" sid="ce21410" from="localhost" xmpp:version="1.0"',
          'wait="60" requests="2" inactivity="30" maxpause="120" polling="2" ver="1.8" secure="true" />'
        ].join " "
      end
      let(:is_open_stream?) { ->(data) { x = Ox.parse(data); ["2", "localhost"] == [x[:rid], x[:to]] } }
      let(:is_login?) { ->(data) { x = Ox.parse(data); ["3", "ce21410"] == [x[:rid], x[:sid]] } }

      context "when session successfuly binded" do
        before do
          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_open_stream?)
            .to_return(body: successful_open_stream)

          stub_request(:post, "http://localhost:5280/http-bind")
            .with(body: is_login?)
            .to_return(body: successful_login)
        end

        it { expect(bosh_session).to be_alive }
      end

      context "when couldn't open stream" do
        context "when response body missed authid attribute" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind" sid="ce21410" />' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: malformed_body)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
          end

          it { expect { bosh_session }.to raise_error Jabber::XMLMalformedError, "Couldn't find <body /> attribute [authid]" }
        end

        context "when response body missed sid attribute" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind" authid="3780309894" />' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: malformed_body)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
          end

          it { expect { bosh_session }.to raise_error Jabber::XMLMalformedError, "Couldn't find <body /> attribute [sid]" }
        end

        context "when response was not 200 OK" do
          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: "Foo", status: 401)

            WebMock.should_not have_requested(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
          end

          it { expect { bosh_session }.to raise_error Net::HTTPBadResponse }
        end
      end

      context "when couldn't login in opened stream" do
        context "when response is a malformed xml without IQ tag" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind"></body>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: malformed_body)
          end

          it { expect { bosh_session }.to raise_error Jabber::XMLMalformedError, "Couldn't find xml tag <iq/>" }
        end

        context "when response has type not equal 'result'" do
          let(:malformed_body) { '<body xmlns="http://jabber.org/protocol/httpbind"><iq type="error" xmlns="jabber:client" id="2034"/></body>' }

          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: malformed_body)
          end

          it { expect { bosh_session }.to raise_error Jabber::AuthenticationError, "Failed to login" }
        end

        context "when response was not 200 OK" do
          before do
            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_open_stream?)
              .to_return(body: successful_open_stream)

            stub_request(:post, "http://localhost:5280/http-bind")
              .with(body: is_login?)
              .to_return(body: "Foo", status: 401)
          end

          it { expect { bosh_session }.to raise_error Net::HTTPBadResponse }
        end
      end
    end
  end

  describe "#to_json" do
    let(:bosh_session) { described_class.bind("strech@localhost/resource", "password", use_sasl: false) }
    let(:successful_login) { '<body xmlns="http://jabber.org/protocol/httpbind"><iq type="result" xmlns="jabber:client" id="2034"/></body>' }
    let(:successful_open_stream) do
      [
        '<body xmlns="http://jabber.org/protocol/httpbind" xmlns:xmpp="urn:xmpp:xbosh" xmlns:stream="http://etherx.jabber.org/streams"',
        'authid="3780309894" sid="ce21410" from="localhost" xmpp:version="1.0"',
        'wait="60" requests="2" inactivity="30" maxpause="120" polling="2" ver="1.8" secure="true" />'
      ].join " "
    end
    let(:is_open_stream?) { ->(data) { x = Ox.parse(data); ["2", "localhost"] == [x[:rid], x[:to]] } }
    let(:is_login?) { ->(data) { x = Ox.parse(data); ["3", "ce21410"] == [x[:rid], x[:sid]] } }

    let(:json) { JSON.parse(bosh_session.to_json) }

    before do
      stub_request(:post, "http://localhost:5280/http-bind")
        .with(body: is_open_stream?)
        .to_return(body: successful_open_stream)


      stub_request(:post, "http://localhost:5280/http-bind")
        .with(body: is_login?)
        .to_return(body: successful_login)
    end

    it { expect(json).to have_key "jid" }
    it { expect(json).to have_key "rid" }
    it { expect(json).to have_key "sid" }

    it { expect(json["jid"]).to eq "strech@localhost/resource"}
    it { expect(json["rid"]).to eq "3"}
    it { expect(json["sid"]).to eq "ce21410"}
  end
end
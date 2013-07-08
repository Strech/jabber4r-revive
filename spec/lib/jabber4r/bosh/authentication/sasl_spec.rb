# coding: utf-8
require "spec_helper"

describe Jabber::Bosh::Authentication::SASL::Query do
  let(:jid) { Jabber::JID.new("strech@localhost/my-resource") }

  describe "#initialize" do
    context "when jid is a String" do
      let(:auth) { described_class.new("hello@localhost/my-res", "my-password") }

      it { expect { auth }.not_to raise_error TypeError }
    end

    context "when jid is not instance of Jabber::JID or String" do
      let(:auth) { described_class.new(:hello, "my-password") }

      it { expect { auth }.to raise_error TypeError }
    end

    context "when mechanism doesn't exists" do
      let(:auth) { described_class.new("hello@localhost/my-res", "my-password", mechanism: :unknown) }

      it { expect { auth }.to raise_error ArgumentError }
    end
  end

  describe "#plain" do
    let(:auth) { described_class.new(jid, "my-password") }
    let(:auth_xml) { auth.dump.strip.gsub(/[\r\n]+|\s{2,}/, "") }
    let(:correct_xml) { '<auth xmlns="urn:ietf:params:xml:ns:xmpp-sasl" mechanism="PLAIN">0123456789</auth>' }

    before { described_class.stub(:generate_plain).and_return "0123456789" }

    it { expect(auth_xml).to eq correct_xml }
  end

  describe "#plain?" do
    let(:auth) { described_class.new(jid, "my-password") }

    it { expect(auth).to be_plain }
  end
end
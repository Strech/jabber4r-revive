# coding: utf-8
require "spec_helper"

describe Jabber::Bosh::Authentication::NonSASL::Query do
  let(:jid) { Jabber::JID.new("strech@localhost/my-resource") }

  describe "#initialize" do
    context "when create plain non-sasl authentication" do
      let(:auth) { described_class.new(jid, "my-password") }

      it { expect(auth.stream_id).to be_nil }
    end

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

    context "when mechanism is digest and no stream_id is given" do
      let(:auth) { described_class.new("hello@localhost/my-res", "my-password", mechanism: :digest) }

      it { expect { auth }.to raise_error KeyError }
    end
  end

  describe "#plain" do
    let(:auth) { described_class.new(jid, "my-password") }
    let(:auth_xml) { auth.dump.strip.gsub(/[\r\n]+|\s{2,}/, "") }
    let(:correct_xml) do
      '<iq xmlns="jabber:client" type="set" id="auth2"><query xmlns="jabber:iq:auth">' +
      '<username>strech</username><password>my-password</password>' +
      '<resource>my-resource</resource></query></iq>'
    end

    before { Jabber.stub(:gen_random_id).and_return "auth2" }

    it { expect(auth_xml).to eq correct_xml }
  end

  describe "#digest" do
    let(:auth) { described_class.new(jid, "my-password", stream_id: 1, mechanism: :digest) }
    let(:auth_xml) { auth.dump.strip.gsub(/[\r\n]+|\s{2,}/, "") }
    let(:correct_xml) do
      '<iq xmlns="jabber:client" type="set" id="auth2"><query xmlns="jabber:iq:auth">' +
      '<username>strech</username><digest>0123456789</digest>' +
      '<resource>my-resource</resource></query></iq>'
    end

    before { Jabber.stub(:gen_random_id).and_return "auth2" }
    before { described_class.stub(:generate_digest).and_return "0123456789" }

    it { expect(auth_xml).to eq correct_xml }
  end

  describe "#plain?" do
    let(:auth) { described_class.new(jid, "my-password") }

    it { expect(auth).to be_plain }
  end

  describe "#digest?" do
    let(:auth) { described_class.new(jid, "my-password", mechanism: :digest, stream_id: 1) }

    it { expect(auth).to be_digest }
  end
end
# coding: utf-8
require "spec_helper"

describe Jabber::JID do
  describe "#initialize" do
    context "when need parse jid from string" do
      context "when only node given" do
        it { expect { described_class.new "user" }.to raise_error ArgumentError }
      end

      context "when node and host given" do
        subject { described_class.new "user@localhost" }

        its(:node) { should eq "user" }
        its(:host) { should eq "localhost" }
        its(:resource) { should be_nil }
      end

      context "when node, host and resource given" do
        subject { described_class.new "user@localhost/attach" }

        its(:node) { should eq "user" }
        its(:host) { should eq "localhost" }
        its(:resource) { should eq "attach" }
      end

      context "when empty string given" do
        it { expect { described_class.new "" }.to raise_error ArgumentError }
      end
    end

    context "when extra arguments given" do
      context "when only host given" do
        subject { described_class.new "user", "localhost" }

        its(:node) { should eq "user" }
        its(:host) { should eq "localhost" }
      end

      context "when host and resource given" do
        subject { described_class.new "user", "localhost", "attach" }

        its(:node) { should eq "user" }
        its(:host) { should eq "localhost" }
        its(:resource) { should eq "attach" }
      end

      context "when node is fully loaded and host, resource given" do
        subject { described_class.new "user@example.com/bind", "localhost", "attach" }

        its(:node) { should eq "user" }
        its(:host) { should eq "localhost" }
        its(:resource) { should eq "attach" }
      end
    end
  end

  describe "#strip" do
    subject { described_class.new(args).strip }

    context "when JID has no resource" do
      let(:args) { "strech@localhost" }

      its(:to_s) { should eq "strech@localhost" }
    end

    context "when JID has no resource" do
      let(:args) { "strech@localhost/pewpew" }

      its(:to_s) { should eq "strech@localhost" }
    end
  end

  describe "#strip!" do
    subject { described_class.new(args).strip! }

    context "when JID has no resource" do
      let(:args) { "strech@localhost" }

      its(:to_s) { should eq "strech@localhost" }
      its(:resource) { should be_nil }
    end

    context "when JID has no resource" do
      let(:args) { "strech@localhost/pewpew" }

      its(:to_s) { should eq "strech@localhost" }
      its(:resource) { should be_nil }
    end
  end

  describe "#hash" do
    let(:hash) { "strech@pewpew/one".hash }
    subject { described_class.new "strech@pewpew/one" }

    its(:hash) { should eq hash }
  end

  describe "#to_s" do
    context "when only host and domain exists" do
      subject { described_class.new("strech", "localhost").to_s }

      it { should eq "strech@localhost" }
    end

    context "when only host and domain exists" do
      subject { described_class.new("strech", "localhost", "attach-resource").to_s }

      it { should eq "strech@localhost/attach-resource" }
    end
  end

  describe "#==" do
    subject { jid1 == jid2 }

    context "when jids are equal" do
      let(:jid1) { described_class.new "strech@localhost" }
      let(:jid2) { described_class.new "strech@localhost" }

      it { should be_true }
    end

    context "when jids are not equal" do
      let(:jid1) { described_class.new "strech@localhost" }
      let(:jid2) { described_class.new "strech@localhost/resource1" }

      it { should be_false }
    end
  end
end
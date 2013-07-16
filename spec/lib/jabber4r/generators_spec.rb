# coding: utf-8
require "spec_helper"

describe Jabber::Generators do
  before { SecureRandom.stub(:uuid).and_return "very_secret_phrase" }

  describe "::request" do
    let(:rid) { Jabber::Generators::Rid }
    let(:rid_object) { double("object") }

    before { rid.stub(:new).and_return rid_object }
    after { described_class.request }

    it { expect(described_class.request).to eq rid_object }
  end

  describe "::id" do
    context "when prefix is empty" do
      it { expect(described_class.id).to eq "id-very_secret_phrase" }
    end

    context "when there is prefix" do
      it { expect(described_class.id("prefix")).to eq "prefix-very_secret_phrase" }
    end
  end

  describe "::iq" do
    after { described_class.iq }

    it { expect(described_class.iq).to eq "iq-very_secret_phrase" }
  end

  describe "::thread" do
    after { described_class.thread }

    it { expect(described_class.thread).to eq "thread-very_secret_phrase" }
  end
end

describe Jabber::Generators::Rid do
  let(:rid) { described_class.new }

  before { Jabber::Generators::Rid.any_instance.stub(:rand).and_return 1 }

  describe "#initialize" do
    it { expect(rid.value).to eq 1 }
  end

  describe "#next" do
    it { expect(rid.next).to eq 2 }
  end

  describe "#value" do
    before { rid.next }

    it { expect(rid.value).to eq 2 }
  end

  describe "#to_s" do
    before { rid.stub(:value).and_return 3 }

    it { expect(rid.to_s).to eq "3" }
  end
end

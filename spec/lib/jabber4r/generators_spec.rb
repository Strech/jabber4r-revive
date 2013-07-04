# coding: utf-8
require "spec_helper"

describe Jabber::Generators do
  let(:generators) { Jabber::Generators }

  before { SecureRandom.stub(:uuid).and_return "very_secret_phrase" }

  describe "::request" do
    let(:rid) { Jabber::Rid }
    let(:rid_object) { double("object") }

    before { rid.stub(:new).and_return rid_object }

    after { generators.request }

    it { rid.should_receive(:new) }
    it { expect(generators.request).to eq rid_object }
  end

  describe "::id" do
    context "when prefix is empty" do
      it { expect(generators.id).to eq "id-very_secret_phrase" }
    end

    context "when there is prefix" do
      it { expect(generators.id("prefix")).to eq "prefix-very_secret_phrase" }
    end
  end

  describe "::iq" do
    after { generators.iq }

    it { generators.should_receive(:id).with("iq") }
    it { expect(generators.iq).to eq "iq-very_secret_phrase" }
  end

  describe "::thread" do
    after { generators.thread }

    it { expect(generators.thread).to eq "thread-very_secret_phrase" }
  end
end

describe Jabber::Rid do
  let(:rid) { Jabber::Rid.new }

  before { Random.stub(:new_seed).and_return 1}

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
end

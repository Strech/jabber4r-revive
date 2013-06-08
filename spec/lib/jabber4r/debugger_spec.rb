# coding: utf-8
require "spec_helper"

describe Jabber::Debugger do
  let(:debugger) { described_class.clone.instance }
  before { described_class.stub(:instance).and_return debugger }

  describe "#initialize" do
    it { expect(described_class).not_to be_enabled }
  end

  describe "#enable" do
    before { described_class.enable! }

    it { expect(described_class).to be_enabled }
  end

  describe "#disable" do
    before { described_class.disable! }

    it { expect(described_class).not_to be_enabled }
  end

  describe "#logger=" do
    let(:logger) { double("Logger") }

    before { described_class.logger = logger }
    it { expect(debugger.logger).to eq logger }
  end

  describe "generated methods" do
    it { expect(described_class).to respond_to :warn }
    it { expect(described_class).to respond_to :info }
    it { expect(described_class).to respond_to :debug }
  end
end
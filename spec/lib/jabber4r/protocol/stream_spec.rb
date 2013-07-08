# coding: utf-8
require "spec_helper"

describe Jabber::Protocol::Stream do
  let(:session) { double("Session", domain: "localhost") }

  describe "#open" do
    let(:stream) { described_class.new(session) }

    it { expect(stream.open).to eq %Q[<?xml version="1.0" encoding="UTF-8"?>\n<stream:stream xmlns="jabber:client" xmlns:stream="http://etherx.jabber.org/streams" to="localhost" version="1.0">] }
  end

  describe "#close" do
    let(:stream) { described_class.new(session) }

    it { expect(stream.close).to eq "</stream:stream>" }
  end
end

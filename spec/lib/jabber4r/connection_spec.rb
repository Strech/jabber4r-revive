# coding: utf-8
require "spec_helper"

describe Jabber::Connection do
  let(:connection) { described_class.new "localhost" }

  before { TCPSocket.stub(:new).and_return TCPSocketMock.new }

  describe "#connected?" do
    before { connection.connect }

    it { expect(connection).to be_connected }
    it { expect(connection).not_to be_disconnected }
  end

  describe "#disconnected?" do
    it { expect(connection).to be_disconnected }
    it { expect(connection).not_to be_connected }
  end
end

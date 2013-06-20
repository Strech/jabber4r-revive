# coding: utf-8
require "spec_helper"

describe Jabber::Connection do
  let(:connection) { described_class.new "localhost" }

  before { TCPSocket.stub(:new).and_return TCPSocketMock.mock! }

  describe "#connect" do
    before { connection.connect }

    it { expect(connection).to be_connected }
    it { expect(connection.poll_thread).to be_alive }
    it { expect(connection.parser_thread).to be_alive }
    it { expect(connection.socket).not_to be_closed }
  end

  describe "#close" do
    before { connection.connect }
    before { connection.close; sleep 0.01 }

    it { expect(connection).to be_disconnected }
    it { expect(connection.poll_thread).not_to be_alive }
    it { expect(connection.parser_thread).not_to be_alive }
    it { expect(connection.socket).to be_closed }
  end
end

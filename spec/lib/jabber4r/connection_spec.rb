# coding: utf-8
require "spec_helper"

describe Jabber::Connection do
  let(:socket) { TCPSocketMock.new }
  let(:connection) { described_class.new "localhost" }

  before { TCPSocket.stub(:new).and_return socket }

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

  describe "#add_filter" do
    context "when filter name and block is given" do
      before { connection.add_filter("hello") { 1 } }

      it { expect(connection.filters).to have_key "hello" }
    end

    context "when only filter name give" do
      it { expect { connection.add_filter("hello") }.to raise_error ArgumentError }
    end
  end

  describe "#remove_filter" do
    before { connection.add_filter("hello") { 1 } }
    it { expect(connection.filters).to have_key "hello" }

    it "should remove filter" do
      connection.remove_filter("hello")
      expect(connection.filters).not_to have_key "hello"
    end
  end

  describe "#send" do
    let(:handler) { proc { 1 } }

    before { connection.connect }
    before { Thread.stub(:current).and_return "current" }

    context "when own handler is given" do
      before { connection.send("hello", handler) }

      it { expect(connection.handlers).to have_key "current" }
      it { expect(connection.handlers["current"]).to eq handler }

      describe "socket" do
        it { expect(socket.to_s).to eq "hello" }
      end
    end

    context "when only block is given" do
      before { connection.send("hello") { 1 } }

      it { expect(connection.handlers).to have_key "current" }
    end

    context "when handler and block are given" do
      before { connection.send("hello", handler) { 1 } }

      it { expect(connection.handlers).to have_key "current" }
      it { expect(connection.handlers["current"]).to eq handler }
    end

    context "when no handlers and block are given" do
      before { connection.send("hello") }

      it { expect(connection.handlers).to be_empty }
    end
  end

  describe "#receive" do
    let(:thread) { double("Pseudo thread", alive?: true) }
    let(:element) { double("XML Element", element_consumed?: false) }

    let(:consume) { ->(element) { element.stub(:element_consumed?).and_return true } }
    let(:skip) { ->(element) { element.stub(:element_consumed?).and_return false } }

    before { connection.stub :register_parsing_thread }
    before { connection.stub :register_polling_thread }

    context "when handlers are not empty" do
      context "when filters are empty" do
        before do
          thread.should_receive(:wakeup)
          connection.stub(:handlers).and_return({thread => consume})

          connection.receive(element)
        end

        it { expect(connection.handlers).to be_empty }
        it { expect(connection.filters).to be_empty }
      end

      context "when filters are not empty" do
        context "when handler consume element" do
          before do
            thread.should_receive(:wakeup)
            skip.should_not_receive(:call)

            connection.stub(:handlers).and_return({thread => consume})
            connection.stub(:filters).and_return({f1: skip})

            connection.receive(element)
          end

          it { expect(connection.handlers).to be_empty }
          it { expect(connection.filters).not_to be_empty }
        end

        context "when handler doesn't consume element" do
          before do
            thread.should_not_receive(:wakeup)
            consume.should_receive(:call).and_call_original

            connection.stub(:handlers).and_return({thread => skip})
            connection.stub(:filters).and_return({f1: consume})

            connection.receive(element)
          end

          it { expect(connection.handlers).not_to be_empty }
          it { expect(connection.filters).not_to be_empty }
        end
      end
    end

    context "when handlers are empty" do
      context "when filters are empty" do
        before do
          thread.should_not_receive(:wakeup)
          connection.should_receive(:wait_for_consume?).and_return false

          connection.receive(element)
        end

        it { expect(connection.handlers).to be_empty }
        it { expect(connection.filters).to be_empty }
      end

      context "when filters are not empty" do
        before do
          thread.should_not_receive(:wakeup)
          consume.should_receive(:call).and_call_original

          connection.stub(:filters).and_return({f1: consume})

          connection.receive(element)
        end

        it { expect(connection.handlers).to be_empty }
        it { expect(connection.filters).not_to be_empty }
      end
    end

    # TODO : When socket is empty?
  end
end

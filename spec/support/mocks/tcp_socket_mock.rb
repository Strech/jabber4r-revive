# coding: utf-8
require "tempfile"

# Mock of TCPSocket
class TCPSocketMock < IO
  attr_accessor :response

  def self.mock!
    Tempfile.new("tcpsocketmock.sock")
  end

  def readline(some_text = nil)
    response
  end

  def flush
  end

  def write(some_text = nil)
  end

  def readchar
    6
  end

  def read(num)
    num > response.size ? response : response[0..num]
  end
end

# coding: utf-8

# Mock of TCPSocket
class TCPSocketMock
  attr_reader :recorded_data, :response_data, :closed

  def initialize
    @recorded_data = ""
    @closed = false
  end

  def self.mock
    new
  end

  def readline(some_text = nil)
    response
  end

  def flush; end

  def write(some_text = nil)
    @recorded_data << some_text
  end

  def readchar
    6
  end

  def close
    @closed = true
  end

  def closed?
    closed
  end

  def read(num)
    num > response.size ? response : response[0..num]
  end
end

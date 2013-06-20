# coding: utf-8

# Mock of TCPSocket
class TCPSocketMock
  attr_accessor :response

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

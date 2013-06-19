# coding: utf-8

# Mock of TCPSocket
class TCPSocketMock < StringIO
  def to_s
    rewind; read
  end
end

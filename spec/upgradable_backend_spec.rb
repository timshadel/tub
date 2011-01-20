require 'spec_helper'

class Echo < EM::Connection
  def receive_data(data)
    send_data(data)
  end
end


describe TUB::UpgradableTcpServer do
  before do
    start_server DEFAULT_TEST_ADDRESS, DEFAULT_TEST_PORT, :backend => TUB::UpgradableTcpServer, :handler_on_upgrade => Echo do |env|
      body = env.inspect + env['rack.input'].read
      [200, { 'Content-Type' => 'text/html' }, body]
    end
  end
  
  it 'should serve HTTP from the Rack app' do
    get('/?cthis').should include('cthis')
  end
  
  it 'should switch from HTTP to Echo when requested' do
    socket = TCPSocket.new(@server.host, @server.port)
    socket.sync = true
    request = "GET / HTTP/1.1\r\nHost: arst.com\r\nUpgrade: Echo/1.0\r\nConnection: Upgrade\r\n\r\n"

    socket.print request
    out = ''
    selection = IO.select([socket], nil, nil, 0.3)
    while selection && selection[0]
      begin
        line = socket.readline
        out << line
        selection = IO.select([socket], nil, nil, 0.3)
      rescue => ex
        STDERR.puts ex
        break
      end
    end

    status, headers, body = parse_response(out)
    status.should == 101
    headers['Upgrade'].should == 'Echo/1.0'
    headers['Connection'].should == 'Upgrade'
    
    selection = IO.select(nil, [socket], nil, 1.5)

    ["I am in ", " echo", "mode"].each do |e|
      socket.puts(e)
    end

    selection = IO.select([socket], nil, nil, 0.3)
    while selection && selection[0]
      begin
        line = socket.readline
        out << line
        selection = IO.select([socket], nil, nil, 0.3)
      rescue => ex
        STDERR.puts ex
        break
      end
    end
    out.should match("am")
    out.should match("echo")
    out.should match("mode")
    
    socket.close
  end
  
  after do
    stop_server
  end
end

require 'bundler'
Bundler.setup

require 'thin'
require 'tub'

unless Object.const_defined?(:DEFAULT_TEST_ADDRESS)
  DEFAULT_TEST_ADDRESS = '0.0.0.0'
  DEFAULT_TEST_PORT    = 3333
end

module Helpers

  def start_server(address=DEFAULT_TEST_ADDRESS, port=DEFAULT_TEST_PORT, options={}, &app)
    @server = Thin::Server.new(address, port, options, app)
    # @server.ssl = options[:ssl]
    @server.threaded = options[:threaded]
    @server.timeout = 3
    
    @thread = Thread.new { @server.start }
    if options[:wait_for_socket]
      wait_for_socket(address, port)
    else
      # If we can't ping the address fallback to just wait for the server to run
      sleep 1 until @server.running?
    end
  end
  
  def stop_server
    @server.stop!
    @thread.kill
    sleep 0.5
    raise "Reactor still running, wtf?" if EventMachine.reactor_running?
  end
  
  def wait_for_socket(address=DEFAULT_TEST_ADDRESS, port=DEFAULT_TEST_PORT, timeout=5)
    Timeout.timeout(timeout) do
      loop do
        begin
          TCPSocket.new(address, port).close
          return true
        rescue
        end
      end
    end
  end


  def send_data(data)
    socket = TCPSocket.new(@server.host, @server.port)
    socket.write data
    out = socket.read
    socket.close
    out
  end

  def parse_response(response)
    raw_headers, body = response.split("\r\n\r\n", 2)
    raw_status, raw_headers = raw_headers.split("\r\n", 2)

    status  = raw_status.match(%r{\AHTTP/1.1\s+(\d+)\b}).captures.first.to_i
    headers = Hash[ *raw_headers.split("\r\n").map { |h| h.split(/:\s+/, 2) }.flatten ]

    [ status, headers, body ]
  end

  def get(url)
    Net::HTTP.get(URI.parse("http://#{@server.host}:#{@server.port}" + url))
  end

  def post(url, params={})
    Net::HTTP.post_form(URI.parse("http://#{@server.host}:#{@server.port}" + url), params).body
  end
 
end

RSpec.configure do |config|
  config.include Helpers
end
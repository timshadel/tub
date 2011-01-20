#--
# Copyright (c) 2011 Tim Shadel
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'thin'

module TUB
  
  class UpgradeApp
    def initialize(conn, app)
      @conn = conn
      @app = app
    end

    def call(env)
      if env["HTTP_UPGRADE"]
        @conn.upgrade!
        [101, { "Upgrade" => env["HTTP_UPGRADE"], "Connection" => "Upgrade" }, []]
      else
        @app.call(env)
      end
    end
  end
  
  class UpgradableTcpServer < Thin::Backends::TcpServer
    attr_accessor :ssl
    # Thin::Server assumes we'll have options
    def initialize(host, port, options)
      super(host, port)
      UpgradableConnection.initial_handler_class = Thin::Connection
      raise ":handler_on_upgrade must be provided" unless options[:handler_on_upgrade]
      UpgradableConnection.upgraded_handler_class = options[:handler_on_upgrade]
    end
    
    # Connect the server
    def connect
      @signature = EventMachine.start_server(@host, @port, UpgradableConnection, &method(:initialize_connection))
    end

    protected
      # Initialize the HTTP handler when the connection is first created.
      def initialize_connection(connection)
        connection.handler.backend                 = self
        ourApp = UpgradeApp.new connection, @server.app
        connection.handler.app                     = ourApp
        connection.handler.comm_inactivity_timeout = @timeout
        connection.handler.threaded                = @threaded
        connection.handler.can_persist!
        
        @connections << connection.handler
      end
  end
end
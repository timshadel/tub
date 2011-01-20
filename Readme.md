Try It
======

Make a server

    require 'tub'

    class Echo < EM::Connection
      def receive_data(data)
        send_data(data)
      end
    end

    app = lambda{|env| [200, {'Content-Type' => 'text/plain'}, ["Hello world!"]]}

    Thin::Server.start('0.0.0.0', 1345, app, :backend => TUB::UpgradableTcpServer, :handler_on_upgrade => Echo)

Connect to the server

    telnet localhost 1345

Speak HTTP

    GET / HTTP/1.1
    Host: example.com


Now switch protocols

    GET / HTTP/1.1
    Host: example.com
    Upgrade: Echo/1.0
    Connection: Upgrade

And then type anything you want, it'll echo back to you

    Hello world
    Hello world

Have fun!


TODO
======
* Make it actually care about what protocol the client requests and which you offer
* Figure out rackup file
* Show a sample app working in Heroku, with a sample client
* Remove the Rack wrapper app and make it part of the example, but customizable, so you control when upgrade occurs

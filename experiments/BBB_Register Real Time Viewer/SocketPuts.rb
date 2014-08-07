require 'socket'               # Get sockets from stdlib

server = TCPServer.open(2000)  # Socket to listen on port 2000
loop {                         # Servers run forever
    puts "Time now #{Time.new.inspect}"
  client = server.accept       # Wait for a client to connect
  puts "client.gets = #{client.gets}"
  client.close                 # Disconnect from the client
}
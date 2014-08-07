require 'socket'      # Sockets are in standard library

hostname = 'localhost'
port = 2000

begin
    s = TCPSocket.open(hostname, port)
    
    s.puts "From gets"
    s.close               # Close the socket when done
    rescue Exception => e  
        # puts e.message  
        # puts e.backtrace.inspect  
end
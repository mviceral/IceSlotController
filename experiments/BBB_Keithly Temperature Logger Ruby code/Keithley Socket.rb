require 'socket'
 
host = '192.168.1.203'     # The web server
port = 1394                # Default HTTP port

socket = TCPSocket.open(host,port)  # Connect to server

socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)

# Reset default turns the Filter off and format the data
socket.print("*RST;FORM:ELEM READ\r\n")

# Set for F Order is important. must be done first 
socket.print("UNIT:TEMP F,(@101:105)\r\n")

# Set up the channels for temp
socket.print("FUNC 'TEMP', (@101:105)\r\n")\

# Config for Thermocouple
socket.print("TEMP:TRAN TC,(@101:105)\r\n")

# Config for K Couple 
socket.print("TEMP:TC:TYPE K,(@101:105)\r\n")

# Clear Buffer
socket.print("TRAC:CLE\r\n")

# Set number of scans
socket.print("TRIG:COUN 1\r\n")

# Set number of channels
socket.print("SAMP:COUN 5\r\n")

# Set scan list
socket.print("ROUT:SCAN (@101:105)\r\n")

# Start scan when enabled
socket.print("ROUT:SCAN:TSO IMM\r\n")

# Enable scan
socket.print("ROUT:SCAN:LSEL INT\r\n")

timeStop = Time.now+5*60
while Time.now<timeStop # Make it run for 5 mins
    socket.print("READ?\r\n")
    response = socket.recv(  255 ) # Read complete response
    
    # Split response at first blank line into headers and body
    print "Data Received in degrees Fahrenhite is: #{response}"
end
    

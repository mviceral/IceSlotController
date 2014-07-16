require 'timeout'
require 'socket'

if ARGV[0] == nil
	puts "Type in LXI PS command.  '*HELP?' to display all the SCPI command headers available on this device."
	exit
end

host = '192.168.1.241'     # The web server
port = 5025                # port

socket = TCPSocket.open(host,port)  # Connect to server
userinput = ""
while userinput != "BYE"
	print "Type in '*HELP?' - The Help system is made up of a series of commands that can be used to get help on all"
	puts " available commands and details on their syntax."
	userinput = gets.upcase.chomp 
	socket.print("#{userinput}\r\n")
	if userInput[-1] == "?"
		print " Data Received: "
		keepLooping = true
	    while keepLooping
	        begin
	            complete_results = Timeout.timeout(1) do 
						tmp = socket.recv(256)
						if tmp.include? "\r"
							puts "#{tmp}"
						else
							print "#{tmp}"
						end
		    end
	        rescue Timeout::Error
	        	keepLooping = false
	        end
	    end
	end
	
end
socket.close
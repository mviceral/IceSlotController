require 'timeout'
require 'socket'
 
host = '192.168.1.213'     # The web server
port = 5025                # port

socket = TCPSocket.open(host,port)  # Connect to server

# Read the SCPI Status Byte status register,
socket.print("*STB?\r\n")
response = socket.recv(  255 ) # Read complete response
puts "Data Received (STB): #{response}"

# Read the Standard Event Status Register (ESR)
socket.print("*ESR?\r\n")
response = socket.recv(  255 ) # Read complete response
puts "Data Received (ESR): #{response}"

userInput = ""
exitString = "exit"

#
# Setup the user command structure
#

commandList = [
    [   'a',    
        [
            ['*CLS','']
        ],
        'clear the unit to its power-on default settings.'
    ],
    [   'b',
        [
		    ['*RST','']
	    ],
	    'reset the unit.'
    ],
    [   'c', 
        [
    		[ "*CLS","clear the unit to its power-on default settings."], 
		[ "*RST","reset the unit."], 
		[ "OUTP:POW:STAT ON","Turns on that 'Output Enable'"], 
		[ "SOUR:CURR 125.0","program output current to 1.0 A."], 
		[ "SOUR:CURR?","confirm the output current setting (response: 1.0)."], 
		[ "SOUR:VOLT 0.9","program output voltage to 5.0 VDC."], 
		[ "SOUR:VOLT?","confirm the output voltage setting (response: 5.0)."], 
		[ "MEAS:CURR?","measure the actual output current (response: ~ 0.0 with no load on output)."], 
		[ "MEAS:VOLT?","measure the actual output voltage (response: ~ 5.0)."] 
	    ], 
	    'Program a unit with no load at the output to 5 VDC @ 1A, and verify the output.' 
    ],['d',[
		['*CLS','clear the unit to its power-on default settings.'],
		['*RST','reset the unit.'],
		[ "OUTP:POW:STAT ON","Turns on that 'Output Enable'"], 
		[ "SOUR:VOLT 4.0","program output voltage to 4.0 VDC."], 
		['SOU:VOLT:PROT:OVER:LEV','program the OVP trip point to 4.0 VDC.'],
		['SOUR:CURR 1.0','program output current to 1.0 A.'],
		['SOUR:VOLT 4.5','program output voltage to 4.5 VDC.'],
		['STAT:PROT:ENABLE 8','program the unit to report OVP trip.'],
		['STAT:PROT:ENABLE?','confirm that OVP fault is enabled (response: 8).'],
		['STAT:PROT:EVENT?','confirm no faults occurred (response: 0). confirm that the OVP LED is not active.']
	], ' Program a unit with no load at the output to generate a Ethernet OVP Fault upon an overvoltage protection trip condition'],['e',[
		['SOUR:VOLT 7.0','program output voltage to 7.0 VDC - cause OVP trip! confirm that OVP LED is active.'] 
	], "Causes an OVP after calling 'd'."],['bye',nil, 'Exits from code.']] 

while (userInput != exitString)
	puts "List of commands for power supply."
	counter = 0;
	while (counter < commandList.length) 
		subCmd = commandList[counter]
		counter += 1
		puts "'#{subCmd[0]}' - '#{subCmd[2]}'"
	end
	print "Input > "
	userInput = STDIN.gets.chomp()
	puts "\n\n\n"
	if (userInput == exitString)
		puts("Exiting code.")
	else
		counter = 0;
		goodUserInput = false
		while (counter < commandList.length) 
			subCmd = commandList[counter]
			counter += 1
			if (userInput == subCmd[0])
				goodUserInput = true
				puts "Executing - '#{subCmd[2]}'"
				sCpi = subCmd[1]
				counter0 = 0
				#
				# Check to see what's going on...
				#
				# puts "sCpi.length=#{sCpi.length}"
				while (counter0<sCpi.length)
					sCpiCmd = sCpi[counter0]
					counter0 += 1
					puts "'#{sCpiCmd[0]}' - '#{sCpiCmd[1]}'"
					socket.print("#{sCpiCmd[0]}\r\n")
					if sCpiCmd[0][-1] == '?'
						# sleep(0.50)
						print "	Data Received: "
						keepLooping = true
					    while keepLooping
					        begin
					            complete_results = Timeout.timeout(10) do 
									tmp = socket.recv(256)
									if tmp.include? "\r"
										puts "#{tmp}"
										keepLooping = false
										break # break out of time out
									else
										print "#{tmp}"
									end
						    end
					        rescue Timeout::Error
					        	keepLooping = false
					        	puts "- no response."
					        end
					    end
					end
				end
				break
			end
		end
		if (goodUserInput == false)
			puts "'#{userInput}' NOT a legit input."
		end		
	end
	puts "\n"
	print ">"
end

socket.close

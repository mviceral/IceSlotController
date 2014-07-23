require 'timeout'
require 'sqlite3'
require 'beaglebone'
include Beaglebone


executeAllStty = "Yes" # "Yes" if you want to execute all...
baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
if (executeAllStty == "Yes") 
    puts 'Check 1 of 6 - cd /lib/firmware'
    system("cd /lib/firmware")
    
    puts 'Check 2 of 6 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
    system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")
    
	if baudrateToUse == 115200 
    		puts 'Check 3 of 6 - ./openTtyO1Port_115200.exe'
		system("./openTtyO1Port_115200.exe")
	elsif baudrateToUse == 19200 
    		puts 'Check 3 of 6 - ./openTtyO1Port_19200.exe'
		system("./openTtyO1Port_19200.exe")
	elsif baudrateToUse == 9600 
    		puts 'Check 3 of 6 - ./openTtyO1Port_9600.exe'
		system("./openTtyO1Port_9600.exe")
	else
		puts "baudrateToUse=#{baudrateToUse} is not one of the options.  Exiting code..."
	end 

    
    puts 'Check 4 of 6 - stty -F /dev/ttyO1 raw'
    system("stty -F /dev/ttyO1 raw")
    
	if baudrateToUse == 115200 
    		puts 'Check 5 of 6 - stty -F /dev/ttyO1 115200'
		system("stty -F /dev/ttyO1 115200")
	elsif baudrateToUse == 19200 
		puts 'Check 5 of 6 - stty -F /dev/ttyO1 19200'
		system("stty -F /dev/ttyO1 19200")
	elsif baudrateToUse == 9600 
		puts 'Check 5 of 6 - stty -F /dev/ttyO1 9600'
		system("stty -F /dev/ttyO1 9600")
	else
		puts "baudrateToUse=#{baudrateToUse} is not one of the options.  Exiting code..."
	end


end

uart1 = UARTDevice.new(:UART1, 115200)

#
# Read the dump all way down 'Stype:1, RTD100'
#
uart1.each_line { 
    |line|
    puts "#{line}"
    if line.include? "Stype:1, RTD100"
        break;
    end
}

@knownCmds = [
        ["S?","Returns the dynamic values of the ThermalSite unit."],
        ["V?","Returns the static values of the ThermalSite unit."],
        ["T:###.###","Sets the temperature set point of the ThermalSite unit."],
        ["R?","Make the code hang and see if it resets."],
        ["bye","To exit the code."]
    ];
    

def showCmds 
    puts ""
    puts "List of commands:"
    @knownCmds.each do |cmd|
        puts "#{cmd[0]}  -  #{cmd[1]}"
    end
end
    

userInput = ""
while userInput != "BYE"
    showCmds
    print "-> "
	userInput = gets.chomp
	userInput = userInput.upcase
	if userInput != "bye"
	    if userInput == "R?"
    	    #
    	    # If the last character of userInput is '?', definitely expect an answer back.
    	    #
            uart1.write("#{userInput}\n");
            keepLooping = true
            while keepLooping
                begin
                    complete_results = Timeout.timeout(60) do      
                        uart1.each_line { 
                            |line| 
                            puts "#{line}"
                            
                            if line.include? "Stype:1, RTD100"
                                puts "Its Stype:1, RTD100 keepLooping false"
                                keepLooping = false
                                break
                            else
                                puts "Its NOT Stype:1, RTD100. keepLooping true"

                                keepLooping = true
                            end
                        }
                end
                rescue Timeout::Error
                    sleep 10
                    puts "Timout while waiting for reset."
                    uart1.disable
                    uart1 = UARTDevice.new(:UART1, 115200)
                    keepLooping = true
                end
            end
	    elsif userInput[-1] == "?"
    	    #
    	    # If the last character of userInput is '?', definitely expect an answer back.
    	    #
            uart1.write("#{userInput}\n");
            keepLooping = true
            while keepLooping
                begin
                    complete_results = Timeout.timeout(1) do      
                        uart1.each_line { 
                            |line| 
                            puts ""
                            puts "#{line}"
                            keepLooping = false
                            break if line =~ /^@/
                        }
                end
                rescue Timeout::Error
                    sleep 10
                    puts "Trying '#{userInput}' again."
                    uart1.disable
                    uart1 = UARTDevice.new(:UART1, 115200)
                    uart1.write("#{userInput}\n");
                    keepLooping = true
                end
            end
        elsif userInput.include? "T:"
            tempToSet = userInput[2..-1]
            
            #
            # Make sure there should be only 3 max number before the decimal and 3 numbers after the decimal
            #
            numParts = tempToSet.partition(".")
            
            uart1.write("T:\n"); # Sets the flag of ThermalSite to expect and setup a number next to setup the temperature.
            # puts("#{tempToSet}");
            uart1.write("#{tempToSet}\n"); # Sends the temperature to the ThermalSite
            keepLooping = true
            while keepLooping
                begin
                    complete_results = Timeout.timeout(1.0) do      
                        uart1.each_line { 
                            |line| 
                            
                            if line.include? "SP "
                                puts ""
                                puts "#{line}"
                                keepLooping = false
                            else
                                uart1.write("T:\n");
                                uart1.write("#{tempToSet}\n");
                            end
                            break;
                        }
                end
                rescue Timeout::Error
                    puts "Trying '#{userInput}' again."
                    uart1.disable
                    uart1 = UARTDevice.new(:UART1, 115200)
                    uart1.write("T:\n");
                    uart1.write("#{tempToSet}\n");
                    keepLooping = true
                end
            end
	    end
	    
	end
end

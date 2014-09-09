require 'sqlite3'
require 'beaglebone'
include Beaglebone

#
# To use, just put in the text you want to send enclosed in text.  See example line below.
# ->ruby writeUART1.rb "This is the text you want to send to the ThermalSite,"<-
#

# Initialize the pins for device UART1 into UART mode.
puts 'Check 1 of 7 - cd /lib/firmware'
system("cd /lib/firmware")

puts 'Check 2 of 7 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")

puts "Check 3 of 7 - ./openTtyO1Port.exe"
# system("openTtyO1Port.exe")
system("./openTtyO1Port_115200.exe")

puts 'Check 4 of 7 - stty -F /dev/ttyO1 raw'
system("stty -F /dev/ttyO1 raw")

puts "Check 5 of 7 - stty -F /dev/ttyO1 "
system("stty -F /dev/ttyO1 115200")

uart1 = UARTDevice.new(:UART1, 115200)

STDOUT.flush  

userInput = "S?"
=begin
while (userInput == "x" || userInput == "X") == false  do
    puts "S? - which will return the status (dynamic data: ambient temp, current temp, etc)"
    puts "V? - Which will return the version (static temp)"
    puts "T: - Which sets up the TS to take in a number in this specific format ###.### for the next UART write command"
    puts "      to set the new setpoint temperature."
    puts "R? - Reboots the TS."
    puts "X - To exit code.."
    print "> "
    userInput = gets.chomp
    if (userInput == "x" || userInput == "X") == false
        uart1.write("#{userInput}\n");
    end
    puts "\n\n"
end
=end

#
# Continuous loop.  Loop is turned off for now.
#
while true do
	sleep(0.5);
	uart1.write("#{userInput}\n");
	#ARGV.each do|a|
	#	uart1.write("#{a}\n");
	#end    
end

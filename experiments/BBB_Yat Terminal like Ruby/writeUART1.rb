require 'sqlite3'
require 'beaglebone'
include Beaglebone

#
# To use, just put in the text you want to send enclosed in text.  See example line below.
# ->ruby writeUART1.rb "This is the text you want to send to the ThermalSite,"<-
#

# Initialize the pins for device UART1 into UART mode.
baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
=begin
puts 'Check 1 of 7 - cd /lib/firmware'
system("cd /lib/firmware")

puts 'Check 2 of 7 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")

puts "Check 3 of 7 - ./openTtyO1Port_#{baudrateToUse}.exe"
system("../BBB_openTtyO1Port c code/openTtyO1Port_#{baudrateToUse}.exe")

puts 'Check 4 of 7 - stty -F /dev/ttyO1 raw'
system("stty -F /dev/ttyO1 raw")

puts "Check 5 of 7 - stty -F /dev/ttyO1 #{baudrateToUse}"
system("stty -F /dev/ttyO1 #{baudrateToUse}")
=end
uart1 = UARTDevice.new(:UART1, 115200)

# Write data to a UART1
ARGV.each do|a|
	uart1.write("#{a}\n");
end    

#
# Continuous loop.  Loop is turned off for now.
#
while false do
	sleep(2.0);
	ARGV.each do|a|
		uart1.write("#{a}\n");
	end    
end

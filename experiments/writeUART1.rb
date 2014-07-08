require 'sqlite3'
require 'beaglebone'
include Beaglebone

#
# To use, just put in the text you want to send enclosed in text.  See example line below.
# ->ruby writeUART1.rb "This is the text you want to send to the ThermalSite,"<-
#

# Initialize the pins for device UART1 into UART mode.
#puts 'Check 6 of 7 - uart1 = UARTDevice.new(:UART1, 115200)'
uart1 = UARTDevice.new(:UART1, 115200)

# Write data to a UART1
ARGV.each do|a|
	uart1.write("#{a}\r\n");
end    

#
# Continuous loop.  Loop is turned off for now.
#
while false do
	sleep(2.0);
	ARGV.each do|a|
		uart1.write("#{a}\r\n");
	end    
end

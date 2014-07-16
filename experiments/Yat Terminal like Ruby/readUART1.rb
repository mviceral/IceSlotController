require 'sqlite3'
require 'beaglebone'
include Beaglebone

executeAllStty = "Yes" # "Yes" if you want to execute all...
baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
if (executeAllStty == "Yes") 
    puts 'Check 1 of 7 - cd /lib/firmware'
    system("cd /lib/firmware")
    
    puts 'Check 2 of 7 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
    system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")
    
    puts "Check 3 of 7 - ./openTtyO1Port_#{baudrateToUse}.exe"
	system("./openTtyO1Port_#{baudrateToUse}.exe")
    
    puts 'Check 4 of 7 - stty -F /dev/ttyO1 raw'
    system("stty -F /dev/ttyO1 raw")
    
    puts "Check 5 of 7 - stty -F /dev/ttyO1 #{baudrateToUse}"
	system("stty -F /dev/ttyO1 #{baudrateToUse}")
end

puts "Check 6 of 7 - uart1 = UARTDevice.new(:UART1, #{baudrateToUse})"
uart1 = UARTDevice.new(:UART1, baudrateToUse)


puts "Check 7 of 7 - uart1.each_line"
puts "Code is waiting for any responses from the ThermalSite."
uart1.each_line { 
    |line| 
    puts line
}
    

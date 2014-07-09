require 'timeout'
require 'sqlite3'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'AllDuts'
require 'singleton'
require 'forwardable'
include Beaglebone

#
# Notes:  Some code may need to get implemented.  Search for the string below
# - "[ ] Code not done"


#
# July 8, 2014 - Managed to write code that will poll 24 duts.  All duts recording logs in their own database.  The code
# still needs 
#   [ ] to be ensured its functionality
#   [ ] to create a new log file per dut record when the interval of how long it is suppose to wait before creating a new
#       log file is reached.
#
# July 7, 2014 - Worked on polling 24 duts and recording all stats into 24 database.  I'm hoping it'll be able to keep up 
# with how fast the polling interval is after polling and writing all data in to 24 separate dbases.
# 
# July 7, 2014 - Initial software code for polling status data (dynamic data) from a dut (ThermalSite device).
#

TOTAL_DUTS_TO_LOOK_AT  = 24

#
# Create log interval unit: hours
#
createLogInterval_UnitsInHours = 1 


    
    
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
	
	# End of 'if (executeAllStty == "Yes")'
end


puts "Check 6 of 7 - uart1 = UARTDevice.new(:UART1, #{baudrateToUse})"
uart1 = UARTDevice.new(:UART1, baudrateToUse)


puts "Check 7 of 7 - Start polling..."
puts "Press the restart button on the ThermalSite unit..."

=begin
#
# Read the dump all way down 'Stype:1, RTD100' so we could start the process.
#
uart1.each_line { 
    |line|
    puts "#{line}"
    if line.include? "Stype:1, RTD100"
        break;
    end
}
=end
################################################
################################################
#
# Do an infinite loop for this code.
# Do a poll for every pollInterval in seconds
#
pollIntervalInSeconds = 10
waitTime = Time.now+pollIntervalInSeconds
allDuts = AllDuts.new(createLogInterval_UnitsInHours)
while true
    #
    # What if there was a hiccup below and waitTime-Time.now becomes negative
    # The code ensures that the process is exactly going to take place at the given interval.  No lag that
    # takes place on processing data.
    #
    if (waitTime-Time.now)<0
        #
        # The code fix for the scenario above.  I can't get it to activate the code below, unless
        # the code was killed...
        #
        puts "#{Time.now.inspect} Warning - time to complete all polling took longer than poll interval!!!"
        # exit # - the exit code...
        #
        # waitTime = Time.now+pollInterval
    else
        sleep(waitTime-Time.now) 
    end
    waitTime = waitTime+pollIntervalInSeconds
    
    dutNum = 0;
    while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do
        #puts "'#{dutNum}'.statusDbFile = #{allDuts.getDut(dutNum).statusDbFile}"
        #gets
        allDuts.getDut(dutNum).poll(uart1)
        dutNum +=1;
    end            
end

    
#
# Pieces of code
#
=begin
dbFile = "/media/"+@dbaseFolder+"/staticdata#{DutNum}.db"
if (File.file?(dbFile))
    # puts "The dbase folder exists."
    @db = SQLite3::Database.open dbFile
else 
    # puts "The dbase folder->#{dbFile}<- does NOT exists."
    @db = SQLite3::Database.new( dbFile )
    @db.execute("create table 'staticdata' ("+
    "sysTime INTEGER,"+     # time of record in BBB
    "tSetp REAL,"+          # 'tSetp' temperature set point
    "Adc0Type TEXT,"+       # 'Adc0Type' ==1?"RTD100":(Adc0Type==2?"NTC30K":"UnKnown")) sensor type
    "tuneKp REAL,"+         # 'tuneKp, tuneKi, tuneKd' P.I.D.   Proportional integral derivative controler
    "tuneKi REAL,"+
    "tuneKd REAL,"+
    "sysTime INTEGER"+      # 'TCCOMPILEDATE', 'TCCOMPILETIME' Version
    ");")
end
=end
    
                
=begin
dbFile = "/media/"+@dbaseFolder+"/setTemp#{DutNum}.db"
if (File.file?(dbFile))
    # puts "The dbase folder exists."
    @db = SQLite3::Database.open dbFile
else 
    # puts "The dbase folder->#{dbFile}<- does NOT exists."
    @db = SQLite3::Database.new( dbFile )
    @db.execute("create table 'setTemp' ("+
    "sysTime INTEGER,"+     # time of record in BBB in which the set temp confirmation is received from 
                            # the ThermalSite unit.
    "newSetTemp REAL"+      # The new set temperature.
    ");")
end

#
# Ensure that database table for reset request is present...
#
dbFile = "/media/"+@dbaseFolder+"/resetRequest#{DutNum}.db"
if (File.file?(dbFile))
    # puts "The dbase folder exists."
    @db = SQLite3::Database.open dbFile
else 
    # puts "The dbase folder->#{dbFile}<- does NOT exists."
    @db = SQLite3::Database.new( dbFile )
    @db.execute("create table 'resetRequest' ("+
    "sysTime INTEGER"+     # time of record in BBB in which the reset was done on the ThermalSite unit.
    ");")
end
=end
                

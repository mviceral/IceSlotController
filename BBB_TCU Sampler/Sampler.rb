require 'timeout'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'ThermalSiteDevices'
include Beaglebone
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
#
# Special not regarding file openTtyO1Port_115200.exe, this comes from the folder BBB_openTtyO1Port c code, and 
# it's compiled as an executable.
#
# 	system("./openTtyO1Port_115200.exe")



#
# Notes:  Some code may need to get implemented.  Search for the string below
# - "[ ] Code not done"

#
# July 10, 2014 - Goal, "Clean the code" that only uses one database.  Made object ThermalSiteDevices that does data
# polling, and logging data.
#
#
# July 9, 2014 - Managed to code where the software is running, and the SD card dies suddenly (i.e. it's removed), 
# the code continues to run.  When a new SD card is plugged in while the code is running, the code continues to do 
# its task.
#
# Made another version where instead of having 24 databases, and each dbase logs the data per thermal site device, 
# I've updated the code to just use one database.  The reason for the transition was to minimize the time of 
# interval when creating a new database when the log interval time is reached.
#
#
# July 8, 2014 - Managed to write code that will poll 24 duts.  All duts recording logs in their own database.  The 
# code still needs 
#   [ ] to be ensured its functionality
#   [ ] to create a new log file per dut record when the interval of how long it is suppose to wait before creating 
# a new log file is reached.
#
# July 7, 2014 - Worked on polling 24 duts and recording all stats into 24 database.  I'm hoping it'll be able to 
# keep up with how fast the polling interval is after polling and writing all data in to 24 separate dbases.
# 
# July 7, 2014 - Initial software code for polling status data (dynamic data) from a dut (ThermalSite device).
#

TOTAL_DUTS_TO_LOOK_AT  = 24

#
# Create log interval unit: hours
#
createLogInterval_UnitsInHours = 1 

#
# Do a poll for every pollInterval in seconds
#
pollIntervalInSeconds = 10 

executeAllStty = "Yes" # "Yes" if you want to execute all...
baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
if (executeAllStty == "Yes") 
    # puts 'Check 1 of 7 - cd /lib/firmware'
    system("cd /lib/firmware")
    
    # puts 'Check 2 of 7 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
    system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")
    
    # puts 'Check 4 of 7 - stty -F /dev/ttyO1 raw'
    system("stty -F /dev/ttyO1 raw")
    
    # puts "Check 5 of 7 - stty -F /dev/ttyO1 #{baudrateToUse}"
	system("stty -F /dev/ttyO1 #{baudrateToUse}")
	
    # puts "Check 3 of 7 - ./openTtyO1Port_#{baudrateToUse}.exe"
	# system("../BBB_openTtyO1Port c code/openTtyO1Port_115200.exe")
	system("./openTtyO1Port_115200.exe")
	
	# End of 'if (executeAllStty == "Yes")'
end


# puts "Check 6 of 7 - uart1 = UARTDevice.new(:UART1, #{baudrateToUse})"
uart1 = UARTDevice.new(:UART1, baudrateToUse)

#
# Flush out the uart if there is anything sitting in the ThermalSite buffer.
#
=begin
puts "Flushing out ThermalSite uart."
keepLooping = false # turned off code cuz it didn't have any effect on getting goog UART connection.
while keepLooping
    begin
        complete_results = Timeout.timeout(1) do      
            uart1.each_line { 
                |line| 
                puts "' -- ${line}"
            }
    end
    rescue Timeout::Error
        puts "Done flushing out ThermalSite uart."
        uart1.disable   # uart1Param variable is now dead cuz it timed out.
        uart1 = UARTDevice.new(:UART1, 115200)  # replace the dead uart variable.
        keepLooping = false     # loops out of the keepLooping loop.
    end
end
=end



#puts "Check 7 of 7 - Start polling..."
#puts "Press the restart button on the ThermalSite unit..."
puts "Logging 23 dut thermalsites."
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
#
ThermalSiteDevices.setTotalHoursToLogData(createLogInterval_UnitsInHours)
waitTime = Time.now+pollIntervalInSeconds
# allDuts = AllDuts.new(createLogInterval_UnitsInHours)
switcher = 0
while true
    #
    # Gather data...
    #
    # puts "Start polling: #{Time.now.inspect}"
    ThermalSiteDevices.pollDevices(uart1)
    switcher+=1
    if switcher%2==0
        print "|"
    else
        print "*"
    end
    # puts "Done polling: #{Time.now.inspect}"
    ThermalSiteDevices.logData
    # puts "Done logging: #{Time.now.inspect}"

    #
    # What if there was a hiccup and waitTime-Time.now becomes negative
    # The code ensures that the process is exactly going to take place at the given interval.  No lag that
    # takes place on processing data.
    #
    if (waitTime-Time.now)<0
        #
        # The code fix for the scenario above.  I can't get it to activate the code below, unless
        # the code was killed...
        #
        puts "#{Time.now.inspect} Warning - time to complete polling took longer than poll interval!!!"
        # exit # - the exit code...
        #
        # waitTime = Time.now+pollInterval
    else
        sleep(waitTime.to_f-Time.now.to_f) 
    end
    waitTime = waitTime+pollIntervalInSeconds
end

    
#
# Pieces of code
# Tables for static data, when temperature set point was called, and reset request.
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
                
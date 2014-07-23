require 'timeout'
require 'sqlite3'
require 'beaglebone'
include Beaglebone

#
# There is definitely a code section that needs to be tested in this module.
#
# - # Code not tested!!!!

#
<<<<<<< HEAD
# Initial software code for setting the set-point temperature of a dut (ThermalSite device).
=======
# Initial software code for setting the set-point temperature of a dut (ThermalSite device).  Records the time
# when the temperature was set in the database.
>>>>>>> 7e5638936cd45d04f347b5d28e72a50ba7f6ba58
#

if ARGV.length == 0
    abort "\nError: Temperature is required. Aborting...\n\n"
end

tempToSet = ARGV[0]
#puts "Userinput temperature is '#{ARGV[0]}'"

#
# Do some data verification...
#

TotalDutsToLookAt = 24
DutNum=1

NO_GOOD_DBASE_FOLDER = "No good database folder"

#
# Variable setup when to make a copy of the data log.
#
logCompletesAt = Time.new(2014,6,30,14,43,0);

logYear = '%04d' % logCompletesAt.year.to_i
logMonth = '%02d' % logCompletesAt.month.to_i
logDay = '%02d' % logCompletesAt.day.to_i
logHour = '%02d' % logCompletesAt.hour.to_i
logMin = '%02d' % logCompletesAt.min.to_i

class DataObj
    def initialize()
        #
        # Check if dbase file exists is the SD Card
        #
        dirInMedia = Dir.entries("/media")
        @dbaseFolder = NO_GOOD_DBASE_FOLDER
        for folderItem in dirInMedia
            if (folderItem != "." and folderItem != "..")
                @dbaseFolder = folderItem
            end
        end
        
        if @dbaseFolder != NO_GOOD_DBASE_FOLDER
            #
            # SD Card is present.
            #
            
            #
            # Ensure that database table for static data (version request) is present...
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

            #
            # Ensure that database table for set temperature is present...
            #
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
            
=begin
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

            #
            # End of 'if @dbaseFolder != NO_GOOD_DBASE_FOLDER'
            #
        end
        #
        # End of 'def initialize()'
        #
    end
    
    def dbaseFolder
        @dbaseFolder
    end
    
    def db
        @db
    end
    
end

dataObj = DataObj.new()

executeAllStty = "Yes"  # "Yes" if you want to execute all...
                        # "No" option is given because there was a scenario where it was not needed to call 
                        # steps from 1 down to 5 once the environment was set.
                        
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

#
# Find out if the file records exists...
#
oldLogRecord = "/media/"+dataObj.dbaseFolder+"/#{logYear}#{logMonth}#{logDay}_#{logHour}#{logMin}.db"
if File.file?(oldLogRecord)
    # puts "old log record exists: #{oldLogRecord}"
    dbaseMadeAt = logCompletesAt
else
    # puts "old log record does not exists."
    dbaseMadeAt = nil;
end

puts "Check 6 of 7 - uart1 = UARTDevice.new(:UART1, #{baudrateToUse})"
uart1 = UARTDevice.new(:UART1, baudrateToUse)


puts "Check 7 of 7 - Put a set point on the TS unit..."
puts "Press the restart button on the ThermalSite unit..."


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

#
# Sets the flag of ThermalSite to expect and setup a number next to setup the temperature.
#
uart1.write("T:\n"); 
# puts("#{tempToSet}");
uart1.write("#{tempToSet}\n"); # Sends the temperature to the ThermalSite
keepLooping = true
setTempResponse = "" # This variable will hold the response of ThermalSite when its temperature set point is set.
while keepLooping
    begin
        complete_results = Timeout.timeout(1.0) do      
            uart1.each_line { 
                |line| 
                
                setTempResponse = line
                
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
        uart1.disable
        uart1 = UARTDevice.new(:UART1, 115200)
        uart1.write("T:\n");
        uart1.write("#{tempToSet}\n");
        keepLooping = true
        
        #
        # Handle error logs here.
        #
    end
end

#
# Parse the 'setTempResponse' and get the temperature.
#
newSetPointTemp = setTempResponse[("SP ".length-1)..-1]

#
# Record the instance of setting the temperature setup...
#
if dataObj.dbaseFolder != NO_GOOD_DBASE_FOLDER
    #
    # The database is available, so go ahead and insert the data into the database.
    #
    
	str = "Insert into setTemp(sysTime,newSetTemp) "+
			   "values(    #{Time.now.to_i},#{newSetPointTemp})"
			   
	# puts "#{str}" # check the insert string.

    begin
        dataObj.db.execute "#{str}"
    
        #
        # If the lapsed time has come to make a copy of the log, do it.
        #
        if dbaseMadeAt == nil and currTime >= logCompletesAt.to_i
            #
            # Code not tested!!!!
            # Still not sure how this code block and code condition is suppose to work.
            #
            system("mv "+dataObj.dbFile+" "+dataObj.oldLogRecord)
            dbaseMadeAt = logCompletesAt
            
            #
            # Create a new dbase since we moved the old dbase to a repository...
            #
    	    dataObj = DataObj.new()

        	#
        	# Re-adjust the value of logCompletesAt so it'll create the next log.
        	# 
        	# [code not done...]
        end
        
        rescue SQLite3::Exception => e 
    		puts "Exception occured"
    		puts e
    		
    		dataObj = DataObj.new()
        ensure
    end
    
    #
    # End of 'if dataObj.dbaseFolder != NO_GOOD_DBASE_FOLDER'
    #
else 
    puts "SD card for dbase is not present!!!"
    dataObj = DataObj.new()
    
    #
    # End of 'if dataObj.dbaseFolder != NO_GOOD_DBASE_FOLDER -else'
    #
end

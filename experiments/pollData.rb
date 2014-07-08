require 'timeout'
require 'sqlite3'
require 'beaglebone'
include Beaglebone

#
# Notes:  Some code may need to get implemented.  Search for the string below
# - "[ ] Code not done"


#
# July 7, 2014 - Worked on polling 24 duts and recording all stats into 24 database.  I'm hoping it'll be able to keep up with how 
# fast the polling interval is after polling and writing all data in to 24 separate dbases.
# 
# July 7, 2014 - Initial software code for polling status data (dynamic data) from a dut (ThermalSite device).
#

TOTAL_DUTS_TO_LOOK_AT  = 24
DutNum=0

NO_GOOD_DBASE_FOLDER = "No good database folder"

#
# Create log interval unit: days
#
createLogInterval = 3

#
# Variable setup when to make a copy of the data log.
# Code logic.  If the log file for a given dut is not present, create a log now as a reference.
# If the code restarts, checks the earliest log file created and makes sure to put a new log file 
# based on the given interval of log creation.
# [ ] Code not done
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
            # Ensure that database table for dynamic data (status request) is present...
            #
            DutNum = 0
            begin
            end while DutNum < TOTAL_DUTS_TO_LOOK_AT
            until   do
               puts("Inside the loop i = #$i" )
               $i +=1;
            end            
            dbDynamicData = "/media/"+@dbaseFolder+"/dynamicdata#{DutNum}.db"
            if (File.file?(dbDynamicData))
                # puts "The dbase folder exists."
                @db = SQLite3::Database.open dbDynamicData
            else 
                # puts "The dbase folder->#{dbFile}<- does NOT exists."
                @db = SQLite3::Database.new( dbDynamicData )
                @db.execute("create table 'dynamicdata' ("+
                "sysTime INTEGER,"+     # time of record in BBB
                "ucRUNmode INTEGER,"+   # 'ucRUNmode' 0 == Standby, 1 == Run
                "AmbientTemp REAL,"+    # 'dMeas' ambient temp
                "TempOfDev REAL,"+      # 'Tdut' CastTc - Temp of dev
                "contDir INTEGER,"+     # 'controllerDirection' Heat == 0, Cool == 1
                "Output INTEGER,"+      # 'Output' PWM 0-255
                "Alarm TEXT"+           # 'AlarmStr' The alarm text
                ");")
            end
            
            #
            # Ensure that database table for set temperature is present...
            #
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


puts "Check 7 of 7 - Start polling..."
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
# Do an infinite loop for this code.
# Do a poll for every pollInterval in seconds
#
pollInterval = 1
uartStatusCmd = "S?\n"
statusResponse = "" # This the response from the status/dynamic data query...
waitTime = Time.now+pollInterval
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
        # puts "Hiccup - time for interval too longer than pollInter!!!"
        # puts "Hiccup - time for interval too longer than pollInter!!!"
        # puts "Hiccup - time for interval too longer than pollInter!!!"
        # puts "Hiccup - time for interval too longer than pollInter!!!"
        # exit # - the exit code...
        #
        waitTime = Time.now+pollInterval
    end
    sleep(waitTime-Time.now) 
    waitTime = waitTime+pollInterval
    
    uart1.write("#{uartStatusCmd}");
    keepLooping = true
    
    #
    # Code block for ensuring that status request is sent and the expected response is received.
    #
    while keepLooping
        begin
            complete_results = Timeout.timeout(1) do      
                uart1.each_line { 
                    |line| 
                    statusResponse = line
                    keepLooping = false     # loops out of the keepLooping loop.
                    break if line =~ /^@/   # loops out of the each_line loop.
                }
        end
        rescue Timeout::Error
            uart1.disable   # uart1 variable is now dead cuz it timed out.
            uart1 = UARTDevice.new(:UART1, 115200)  # replace the dead uart variable.
            uart1.write("#{uartStatusCmd}");    # Resend the status request command.

            #
            # Place code here for handling hiccups.
            #
        end
    end
    
    #
    # Parse and save the statusResponse.
    #
    
    #
    # Get the string index [1..-1] because we're skipping the first character '@'
    # Parse the data out.
    #
    ucRUNmode = statusResponse[1..-1].partition(",")
    ambientTemp = ucRUNmode[2].partition(",")
    tempOfDev = ambientTemp[2].partition(",")
    contDir = tempOfDev[2].partition(",")
    output = contDir[2].partition(",")
    alarm = output[2].partition(",")
    #puts "#{ucRUNmode[0]},#{ambientTemp[0]},#{tempOfDev[0]},#{contDir[0]},#{output[0]},#{alarm[0]}"
    #dbDynamicData[DutNum-1]

    if dataObj.dbaseFolder != NO_GOOD_DBASE_FOLDER
        #
        # The database is available, so go ahead and insert the data into the database.
        #
        
		str = "Insert into dynamicdata(sysTime,ucRUNmode      ,AmbientTemp      ,TempOfDev      ,contDir      ,Output      ,Alarm) "+
				   "values(    #{Time.now.to_i},#{ucRUNmode[0]},#{ambientTemp[0]},#{tempOfDev[0]},#{contDir[0]},#{output[0]},\"#{alarm[0]}\")"
				   
		# puts "#{str}" # check the insert string.

        begin
            dataObj.db.execute "#{str}"
        
            if dbaseMadeAt == nil and currTime >= logCompletesAt.to_i 
                system("mv /media/"+dataObj.dbaseFolder+"/temperature.db "+oldLogRecord)
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

end
=begin
uart1.each_line { 
    |line| 

    etime =  line.partition(",")
    etimeV = etime[0].delete(" eTime")
    etimeV = etimeV[1,etimeV.length]
    leftOver = etime[2]
    ambTLabel = leftOver.partition(",")
    leftOver = leftOver[2]
    #puts "etime:#{etime[0]}, ambTLabel:#{ambTLabel[0]}"
    #puts "ambTLabel:#{ambTLabel}"
    ambTValue = ambTLabel[2].partition(",")
    #puts "ambTV:#{ambTValue}"
    ambTV = '%.3f' % ambTValue[0].delete( "C" ).to_f
    setPLabel = ambTValue[2].partition(",")
    #puts "setTLabel:#{setTLabel}"
    setPValue = setPLabel[2].partition(",")
    setPV = '%.3f' % setPValue[0].delete( "C" ).to_f
    #puts "setTV:#{setTValue}"
    casTLabel = setPValue[2].partition(",")
    #puts "casTLabel:#{casTLabel}"
    casTValue = casTLabel[2].partition(",")
    casTV = '%.3f' % casTValue[0].delete( "C" ).to_f
    #puts "casTV:#{casTValue}"
    stypeLabel = casTLabel[2].partition(",")
    stypeValue = stypeLabel[2].partition(",")
    stypeVStripped = stypeValue[0].partition(":")
    
    senRLabel = stypeValue[2].partition(",")
    senRActual = senRLabel[0].partition(":")[2]
    senRActual = '%.3f' % senRActual.delete("ohms").to_f
    senRValue = senRLabel[2].partition(",")
    
    adc0Label = senRValue[2].partition(",")
    adc0Value = senRValue[0].partition(":")[2]
    
    casRLabel = senRValue[2].partition(",")
    casRValue = casRLabel[2].partition(",")
    casRV = '%.3f' % casRValue[0].delete("C").to_f
    
    cooLHeat = casRValue[2].partition(",")
    cooLHeatV = cooLHeat[0]
    outPwrLabel = cooLHeat[2].partition(",")
    outPwrVActual = outPwrLabel[0].partition(":")[2].to_i
    outPwrValue = outPwrLabel[2].partition(",")

    verNLabel = outPwrValue[2].partition(",")
    verNVActual = outPwrValue[0].partition("N:")
    byValue=  verNVActual[2].partition("By:")[2]
    verNVActual =  verNVActual[2].partition("By:")[0]
    currTime = Time.new.to_i
    if dataObj.dbaseFolder != NO_GOOD_DBASE_FOLDER
        #
        # The database is available, so go ahead and insert the data into the database.
        #
        
        if byValue.length > 0
            #
            # We're not initializing, therefore save the data...
            #
    		str = "Insert into tempRec(sysTime         , eTime         , AmbT_C ,  SetP_C,  CasT_C,                   Stype,     SenR_Ohm,            ADC0,  CasR_C,        Activity,        OutPwr_V,              VerN,            By) "+
    				   "values(#{currTime},\"#{etimeV}\",#{ambTV},#{setPV},#{casTV},\"#{stypeVStripped[2]}\",#{senRActual},\"#{adc0Value}\",#{casRV},\"#{cooLHeatV}\",#{outPwrVActual},\"#{verNVActual}\",\"#{byValue}\")"
    		#puts "#{str}"
    		
    		begin
    		    dataObj.db.execute "#{str}"

                if dbaseMadeAt == nil and currTime >= logCompletesAt.to_i 
                    system("mv /media/"+dataObj.dbaseFolder+"/temperature.db "+oldLogRecord)
                    dbaseMadeAt = logCompletesAt
                    
                    #
                    # Create a new dbase since we moved the old dbase to a repository...
                    #
        			dataObj = DataObj.new()
                end
    		    
    		    rescue SQLite3::Exception => e 
        			puts "Exception occured"
        			puts e
        			
        			dataObj = DataObj.new()
    		    ensure
    		    
    		end
        end 
        
    else 
        puts "SD card for dbase is not present!!!"
        dataObj = DataObj.new()
    end
    #puts "->#{etimeV},ambTV:#{ambTV} ,setPV:  #{setPV}, casTV:  #{casTV}, stypeV:#{stypeVStripped[2]},senRV: #{senRActual},    adc0V:#{adc0Value},casRV:  #{casRV}, #{cooLHeatV},outPwrV:  #{outPwrVActual},verNV:#{verNVActual},byV:#{byValue}"
    puts line
}
=end
puts "End code"    

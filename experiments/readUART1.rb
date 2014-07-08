require 'sqlite3'
require 'beaglebone'
include Beaglebone

TotalDutsToLookAt = 24
DutNum=1

NO_GOOD_DBASE_FOLDER = "No good database folder"

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

            #
            # Ensure that database table for dynamic data (status request) is present...
            #
            dbFile = "/media/"+@dbaseFolder+"/dynamicdata#{DutNum}.db"
            if (File.file?(dbFile))
                # puts "The dbase folder exists."
                @db = SQLite3::Database.open dbFile
            else 
                # puts "The dbase folder->#{dbFile}<- does NOT exists."
                @db = SQLite3::Database.new( dbFile )
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
        end
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


puts "Check 7 of 7 - uart1.each_line"
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
    

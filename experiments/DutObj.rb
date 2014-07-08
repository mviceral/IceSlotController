require_relative 'AllDuts'

class DutObj
    NO_GOOD_DBASE_FOLDER = "No good database folder"
    attr_accessor :statusDbFile
    def initialize(indexOfDutParam,createLogInterval_UnitsInHoursParam, arrayParentParam)
        # puts "indexOfDutParam = #{indexOfDutParam} #{__FILE__}-#{__LINE__}"
        # puts "@createLogInterval_UnitsInHoursParam = #{@createLogInterval_UnitsInHoursParam} #{__FILE__}-#{__LINE__}"
        # puts "arrayParentParam = #{arrayParentParam} #{__FILE__}-#{__LINE__}"
        # gets
        @arrayParent = arrayParentParam
        @indexOfDut = indexOfDutParam
        @createLogInterval_UnitsInHours = createLogInterval_UnitsInHoursParam
        
        @db = nil
        #
        # Start a log file.  Scenario - we're going to start the application.  This Dut checks a reference point of when it last logged.
        # If the file is not found, create on immediately, then just checks whether it's time to create a new log based on the last log
        # file created.
        #
        
        #
        # Variable setup when to make a copy of the data log.
        # Code logic.  If the log file for a given dut is not present, create a log now as a reference.
        # If the code restarts, checks the earliest log file created and makes sure to put a new log file 
        # based on the given interval of log creation.
        # [ ] Code not done
        #
        dutLogFileName = "dutLog#{@indexOfDut}_"
        rootLogPath = "/media/"+self.dbaseFolder+"/"
        dirInMedia = Dir.entries("#{rootLogPath}")
        listOfFiles = Array.new
        for folderItem in dirInMedia
            if folderItem.include? dutLogFileName
                listOfFiles.push(folderItem)
            end
            # End of 'for folderItem in dirInMedia'
        end
        
        # puts "Check 1 #{@indexOfDutParam} #{__FILE__}-#{__LINE__}"
        if listOfFiles.count > 0
            # puts "Check 2 #{@indexOfDutParam} #{__FILE__}-#{__LINE__}"
            #
            # From the list, get the newest file modified date.
            #
            latestLogDateFile = ""
            latestModeTime = nil
            listOfFiles.each { 
                |file|
                # puts "Check 3 #{@indexOfDutParam} #{__FILE__}-#{__LINE__}"
                # puts "checking file - #{file}"
                modTime = File.mtime("#{rootLogPath}#{file}")
                if latestModeTime.nil?
                    latestModeTime = modTime
                    latestLogDateFile = file
                elsif latestModeTime < modTime
                    latestModeTime = modTime
                    latestLogDateFile = file
                end
                # puts "time modification of #{rootLogPath}#{file} : #{modTime}"
            }
            
            # puts "The latest log file is : #{latestLogDateFile}" # Checked.
            
            #
            # Parse the date from date text of 'latestLogDateFile'
            #
            justTheDate = latestLogDateFile[dutLogFileName.length..-1]
            # puts "justTheDate = #{justTheDate}"
            logYear = justTheDate[0,4].to_i
            logMonth = justTheDate[4,2].to_i
            logDay = justTheDate[6,2].to_i
            logHour = justTheDate[9,2].to_i
            logMin = justTheDate[11,2].to_i
            
            # puts "logYear=#{logYear}, logMonth = #{logMonth}, logDay = #{logDay}, logHour = #{logHour}, logMin = #{logMin}"
            
            #
            # Makes a date time object from the string file name.
            #
            logCompletedAt = Time.new(logYear,logMonth,logDay,logHour,logMin,0);
            nextLogCreation = logCompletedAt+@createLogInterval_UnitsInHours*60   # *60*60 converts @createLogInterval_UnitsInHours to seconds
            
            # puts "logCompletedAt = #{logCompletedAt.inspect}"
            # puts "nextLogCreation = #{nextLogCreation.inspect}"
            # puts "at #{__FILE__}-#{__LINE__}"
            # gets # pause
    
            timeNow = Time.now
            if nextLogCreation<timeNow
                # puts "Check 4 Log file is over due #{__FILE__}-#{__LINE__}"
                #
                # It's time to make a new log.  Move the current database to a log file...
                #
                logYear = '%04d' % timeNow.year.to_i
                logMonth = '%02d' % timeNow.month.to_i
                logDay = '%02d' % timeNow.day.to_i
                logHour = '%02d' % timeNow.hour.to_i
                logMin = '%02d' % timeNow.min.to_i
                
                newLogFileName = "#{dutLogFileName}#{logYear}#{logMonth}#{logDay}_#{logHour}#{logMin}.db" 
                cmd =  "mv /media/"+dbaseFolder+"/dutLog#{@indexOfDut}.db "+"/media/"+dbaseFolder+"/"+newLogFileName
                system(cmd) # moves the dutLogXXX.db to a log file record
                
                cmd =  "touch "+"/media/"+dbaseFolder+"/"+newLogFileName
                # puts cmd    # If the dutLogXXX.db does not exist, the log file will not exists either.  Therefore, 
                            # just create a dummy log file so we'll have a reference.
                system(cmd)
                # puts "at #{__FILE__}-#{__LINE__}"
                # gets # pause
                
                #
                # Create a new dbase since we moved the old dbase to a repository...
                #
        	    @arrayParent[@indexOfDut] = DutObj.new(@indexOfDut,@createLogInterval_UnitsInHours,@arrayParent)
        	    
        	    # End of 'if nextLogCreation<Time.now'
            end
            # End of 'if listOfFiles.count > 0'
        else
            #
            # There is no log file found from the search.  Create one as a base of when the we started logging...
            #
            puts "There is no log file found from the search.  Create one as a base of when the we started logging..."
            
            timeNow = Time.now
            logYear = '%04d' % timeNow.year.to_i
            logMonth = '%02d' % timeNow.month.to_i
            logDay = '%02d' % timeNow.day.to_i
            logHour = '%02d' % timeNow.hour.to_i
            logMin = '%02d' % timeNow.min.to_i
            
            newLogFileName = "#{dutLogFileName}#{logYear}#{logMonth}#{logDay}_#{logHour}#{logMin}.db" 
            cmd =  "touch /media/"+dbaseFolder+"/"+newLogFileName
            puts cmd # Check it
            system(cmd)
            # End of 'if listOfFiles.count > 0 ELSE'
        end

        # End of 'def initialize()'
    end
    
    def poll(uart1Param)
        # puts "within poll. statusDbFile=#{statusDbFile}"
        # gets
        uartStatusCmd = "S?\n"
        uart1Param.write("#{uartStatusCmd}");
        statusResponse = "" # This the response from the status/dynamic data query...
        keepLooping = true
        #
        # Code block for ensuring that status request is sent and the expected response is received.
        #
        while keepLooping
            begin
                complete_results = Timeout.timeout(1) do      
                    uart1Param.each_line { 
                        |line| 
                        statusResponse = line
                        keepLooping = false     # loops out of the keepLooping loop.
                        break if line =~ /^@/   # loops out of the each_line loop.
                    }
            end
            rescue Timeout::Error
                uart1Param.disable   # uart1Param variable is now dead cuz it timed out.
                uart1Param = UARTDevice.new(:uart1Param, 115200)  # replace the dead uart variable.
                uart1Param.write("#{uartStatusCmd}");    # Resend the status request command.
    
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
        #@statusDbFile[DutNum-1]
    
        if dbaseFolder != NO_GOOD_DBASE_FOLDER
            #
            # The database is available, so go ahead and insert the data into the database.
            #
            
    		str = "Insert into dutLog(sysTime,ucRUNmode      ,AmbientTemp      ,TempOfDev      ,contDir      ,Output      ,Alarm) "+
    				   "values(    #{Time.now.to_i},#{ucRUNmode[0]},#{ambientTemp[0]},#{tempOfDev[0]},#{contDir[0]},#{output[0]},\"#{alarm[0]}\")"
    				   
    		# puts "#{str}" # check the insert string.
    
            begin
                db.execute "#{str}"
                
                #
                # See if the dbase log file needs to be updated.
                #
            
                rescue SQLite3::Exception => e 
            		puts "Exception occured"
            		puts e
            		
            		@arrayParent[@indexOfDut] = DutObj.new(@indexOfDut,@createLogInterval_UnitsInHours,@arrayParent)

            	    # End of 'rescue SQLite3::Exception => e'
                ensure
                
                # End of 'begin' code block that will handle exceptions...
            end
            
            # End of 'if DutObj.dbaseFolder != NO_GOOD_DBASE_FOLDER'
        else 
            puts "SD card for dbase is not present!!!"
            @arrayParent[@indexOfDut] = DutObj.new(@indexOfDut,@createLogInterval_UnitsInHours,@arrayParent)


            # End of 'if DutObj.dbaseFolder != NO_GOOD_DBASE_FOLDER - ELSE'
        end
        
        # End of 'def poll()'
    end
    
    def statusDbFile
        @statusDbFile
    end
    def dbaseFolder
        if @db.nil?
            #
            # Check if dbase file exists is the SD Card
            #
            @dbaseFolder = NO_GOOD_DBASE_FOLDER
            dirInMedia = Dir.entries("/media")
            for folderItem in dirInMedia
                if (folderItem != "." and folderItem != "..")
                    @dbaseFolder = folderItem
                    # End of 'if (folderItem != "." and folderItem != "..")'
                end
                # End of 'for folderItem in dirInMedia'
            end

            if @dbaseFolder != NO_GOOD_DBASE_FOLDER
                #
                # SD Card is present.
                #
                
                #
                # Ensure that database table for static data (version request) is present...
                #
                
                #
                # Ensure that database table for dynamic data (status request) is present...
                #
                @statusDbFile = "/media/"+@dbaseFolder+"/dutLog#{@indexOfDut}.db"
                # puts "@statusDbFile=#{@statusDbFile}"
                if (File.file?(@statusDbFile))
                    # puts "The dbase folder exists."
                    @db = SQLite3::Database.open @statusDbFile
                    # End of 'if (File.file?(@statusDbFile))'
                else 
                    # puts "The dbase folder->#{dbFile}<- does NOT exists."
                    @db = SQLite3::Database.new( @statusDbFile )
                    @db.execute("create table 'dutLog' ("+
                    "sysTime INTEGER,"+     # time of record in BBB
                    "ucRUNmode INTEGER,"+   # 'ucRUNmode' 0 == Standby, 1 == Run
                    "AmbientTemp REAL,"+    # 'dMeas' ambient temp
                    "TempOfDev REAL,"+      # 'Tdut' CastTc - Temp of dev
                    "contDir INTEGER,"+     # 'controllerDirection' Heat == 0, Cool == 1
                    "Output INTEGER,"+      # 'Output' PWM 0-255
                    "Alarm TEXT"+           # 'AlarmStr' The alarm text
                    ");")
                    # End of 'if (File.file?(@statusDbFile)) ELSE'
                end
                
                #
                # Ensure that database table for set temperature is present...
                #
                
                # End of 'if @dbaseFolder != NO_GOOD_DBASE_FOLDER'
            end

            
            # End of 'if @db.nil?'
        end
        
        return @dbaseFolder
            
        # End of 'def dbaseFolder'
    end
    
    def db
        @db
        # End of 'def db'
    end
    # End of 'class DutObj'
end

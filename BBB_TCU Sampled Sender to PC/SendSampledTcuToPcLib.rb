require 'sqlite3'
require 'rest_client'
require 'singleton'
require 'forwardable'
require_relative '../BBB_Shared Memory Ruby/SharedMemory'

class SendSampledTcuToPCLib
    include Singleton
    NO_GOOD_DBASE_FOLDER = "No good database folder"
    MOUNT_CARD_DIR = "/mnt/card"
    TOTAL_DUTS_TO_LOOK_AT = 24
    ITS_MOUNTED = "It's mounted."
    BbbToPc = 'http://192.168.7.1'
    PcToSamePc = "localhost"
    SendToPc = BbbToPc

    def refreshDbHandler
        # puts "refreshDbHandler got called."
        # puts "@statusDbFile=#{@statusDbFile} #{__FILE__}-#{__LINE__}"
        # puts "At pause - "
        # gets
        if (File.file?(@statusDbFile))
            # puts "The dbase folder exists."
            @db = SQLite3::Database.open @statusDbFile
            # End of 'if (File.file?(@statusDbFile))'
        else 
            @db = SQLite3::Database.new( @statusDbFile )
            # @db.execute("create table 'DutLog' ("+
            # "sysTime INTEGER,"+     # time of record in BBB
            # "dutNum INTEGER,"+      # 'dutNum' the dut number reference of the data
            # "ucRUNmode INTEGER,"+   # 'ucRUNmode' 0 == Standby, 1 == Run
            # "AmbientTemp REAL,"+    # 'dMeas' ambient temp
            # "TempOfDev REAL,"+      # 'Tdut' CastTc - Temp of dev
            # "contDir INTEGER,"+     # 'controllerDirection' Heat == 0, Cool == 1
            # "Output INTEGER,"+      # 'Output' PWM 0-255
            # "Alarm TEXT"+           # 'AlarmStr' The alarm text
            # ");")

            @db.execute("create table 'DutLog' ("+
            "dutData TEXT"+     # 'dutNum' the dut number reference of the data
            ");")
            # End of 'if (File.file?(@statusDbFile)) ELSE'
        end
    end


    def getLastLogCompletedAt
        # puts "getLastLogCompletedAt 1"
        if dbaseFolder == NO_GOOD_DBASE_FOLDER
            # puts "getLastLogCompletedAt 2"
            return nil
            # End of 'if dbaseFolder == NO_GOOD_DBASE_FOLDER'
        end
        # puts "getLastLogCompletedAt 3"
        
        #
        # Start a log file.  Scenario - we're going to start the application.  This Dut checks a reference point of when 
        # it last logged. If the file is not found, create one immediately, then just checks whether it's time to create 
        # a new log based on the last log file created.
        #
        
        #
        # Variable setup when to make a copy of the data log.
        # Code logic.  If the log file for a given dut is not present, create a log now as a reference.
        # If the code restarts, checks the earliest log file created and makes sure to put a new log file 
        # based on the given interval of log creation.
        #
        @dutLogFileName = "dutLog_"
        rootLogPath = self.dbaseFolder+"/"
        # puts "rootLogPath= #{rootLogPath} #{__FILE__}-#{__LINE__}"
        # puts "@dutLogFileName= #{@dutLogFileName} #{__FILE__}-#{__LINE__}"
        dirInMedia = Dir.entries("#{rootLogPath}")
        listOfFiles = Array.new
        for folderItem in dirInMedia
            # puts "checking folderItem - '#{folderItem}' #{__FILE__}-#{__LINE__}"
            if folderItem.include? @dutLogFileName
                listOfFiles.push(folderItem)
            end
            # End of 'for folderItem in dirInMedia'
        end
        
        # puts "Check 1 #{__FILE__}-#{__LINE__}"
        if listOfFiles.count > 0
            # puts "Check 2 #{__FILE__}-#{__LINE__}"
            #
            # From the list, get the newest file modified date.
            #
            latestLogDateFile = ""
            latestModeTime = nil
            listOfFiles.each { 
                |file|
                # puts "Check 3 #{Param} #{__FILE__}-#{__LINE__}"
                # puts "checking file - #{file} #{__FILE__}-#{__LINE__}"
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
            justTheDate = latestLogDateFile[@dutLogFileName.length..-1]
            # puts "justTheDate = #{justTheDate}"
            logYear = justTheDate[0,4].to_i
            logMonth = justTheDate[4,2].to_i
            logDay = justTheDate[6,2].to_i
            logHour = justTheDate[9,2].to_i
            logMin = justTheDate[11,2].to_i
            
            # puts "logYear=#{logYear}, logMonth = #{logMonth}, logDay = #{logDay}, logHour = #{logHour}, 
            # logMin = #{logMin}"
            
            #
            # Makes a date time object from the string file name.
            #
            # @logCompletedAt = Time.new(logYear,logMonth,logDay,logHour,logMin,0);
            return Time.new(logYear,logMonth,logDay,logHour,logMin,0);
            # End of 'if listOfFiles.count > 0'
        else
            # puts "Returning time now...  #{__FILE__}-#{__LINE__}"
            return Time.now    
            # End of 'if listOfFiles.count > 0 ELSE'
        end
        # End of 'def getLastLogCompletedAt'
    end
    
    def logCompletedAt
        # puts "within logCompletedAt A  #{__FILE__}-#{__LINE__}"
        # gets
        if @logCompletedAt.nil?
            # puts "within logCompletedAt B  #{__FILE__}-#{__LINE__}"
            # gets
            # puts "@logCompletedAt.nil? is true"
            #
            # Just call initialize again to get a legit value for @logCompletedAt
            #
            initialize(@createLogInterval_UnitsInHours)
            # puts "Test B #{__FILE__}-#{__LINE__}"
            # gets
            # End of 'if @logCompletedAt.nil?'
        end
        # puts "@logCompletedAt = #{@logCompletedAt}  #{__FILE__}-#{__LINE__}"
        # gets
        @logCompletedAt
        # End of 'def logCompletedAt'
    end


    def initialize
        # puts "DutObj got initialized."
        system("umount /mnt/card") # unmount the card, case it crashes and the user # puts in a new card.
        @createLogInterval_UnitsInHours = 1 
        @db = nil
        @statusResponse = Array.new(TOTAL_DUTS_TO_LOOK_AT)
        # puts "A @logCompletedAt = #{@logCompletedAt}  #{__FILE__}-#{__LINE__}"
        # gets
        @logCompletedAt = getLastLogCompletedAt()
        # puts "B @logCompletedAt = #{@logCompletedAt}  #{__FILE__}-#{__LINE__}"
        # gets
        @dbaseFolder = NO_GOOD_DBASE_FOLDER        
        # puts "dbaseFolder #{dbaseFolder}  #{__FILE__}-#{__LINE__}"
        # puts "NO_GOOD_DBASE_FOLDER = #{NO_GOOD_DBASE_FOLDER}  #{__FILE__}-#{__LINE__}"
        
        # puts "Check E"
        if dbaseFolder != NO_GOOD_DBASE_FOLDER
            puts "Initlized C #{__LINE__}-#{__FILE__}"
            # puts "Check A #{__FILE__}-#{__LINE__}"
            # gets
            if @logCompletedAt.nil? 
                puts "Initlized D #{__LINE__}-#{__FILE__}"
                # puts "Check B #{__FILE__}-#{__LINE__}"
                # puts "Pause here #{__FILE__}-#{__LINE__}"
                # gets
                #
                # There is no log file found from the search.  Create one as a base of when the we started logging...
                #
                # puts "There is no log file found from the search.  Create one as a base for when we started logging..."
                # gets # pause
                
                timeNow = Time.now
                logYear = '%04d' % timeNow.year.to_i
                logMonth = '%02d' % timeNow.month.to_i
                logDay = '%02d' % timeNow.day.to_i
                logHour = '%02d' % timeNow.hour.to_i
                logMin = '%02d' % timeNow.min.to_i
                
                newLogFileName = "#{@dutLogFileName}#{logYear}#{logMonth}#{logDay}_#{logHour}#{logMin}.db" 
                cmd =  "touch "+dbaseFolder+"/"+newLogFileName
                # puts cmd # Check it
                system(cmd)
                @logCompletedAt = getLastLogCompletedAt()
                # End of 'if @logCompletedAt.nil? '
            else
                puts "Initlized E #{__LINE__}-#{__FILE__}"
                # puts "Check C #{__FILE__}-#{__LINE__}"
                # gets
                @nextLogCreation = @logCompletedAt+@createLogInterval_UnitsInHours*60   # *60*60 converts 
                                                                                      # @createLogInterval_UnitsInHours 
                                                                                      # to seconds
                # puts "@logCompletedAt = #{@logCompletedAt.inspect}"
                # puts "@nextLogCreation = #{@nextLogCreation.inspect}"
                # puts "at #{__FILE__}-#{__LINE__}"
                # gets # pause
        
                timeNow = Time.now
                if @nextLogCreation<timeNow
                    puts "Initlized F #{__LINE__}-#{__FILE__}"
                    #
                    # Create new log.
                    #
                    createNewLog(timeNow)
            	    # End of 'if @nextLogCreation<Time.now'
                end
                puts "Initlized G #{__LINE__}-#{__FILE__}"
                # End of 'if @logCompletedAt.nil? ELSE'
            end
            puts "Initlized H #{__LINE__}-#{__FILE__}"
            # End of 'if dbaseFolder != NO_GOOD_DBASE_FOLDER'
        else
            # puts "Check D"
             # printErrorSdCardMissing(__FILE__,__LINE__)
             @db = nil
             # puts "@db to nil '#{@db}' #{__FILE__}-#{__LINE__}"
        end 

        # End of 'def initialize()'
    end

    def createNewLog(timeNow)
        # puts "Within createNewLog A #{__FILE__}-#{__LINE__}"
        if dbaseFolder != NO_GOOD_DBASE_FOLDER
            # puts "Within createNewLog B #{__FILE__}-#{__LINE__}"
            timeNow = Time.at(timeNow)
            # puts "timeNow = #{timeNow} #{__FILE__}-#{__LINE__}"
            # puts "Check 4 Log file is over due #{__FILE__}-#{__LINE__}"
            #
            # It's time to make a new log.  Move the current database to a log file...
            #
            logYear = '%04d' % timeNow.year.to_i
            logMonth = '%02d' % timeNow.month.to_i
            logDay = '%02d' % timeNow.day.to_i
            logHour = '%02d' % timeNow.hour.to_i
            logMin = '%02d' % timeNow.min.to_i
            # puts "Within createNewLog C #{__FILE__}-#{__LINE__}"
            
            newLogFileName = "#{@dutLogFileName}#{logYear}#{logMonth}#{logDay}_#{logHour}#{logMin}.db" 
            # puts "Within createNewLog D #{__FILE__}-#{__LINE__}"
            cmd =  "mv "+dbaseFolder+"/DutLog.db "+dbaseFolder+"/"+newLogFileName
            # puts "cmd = #{cmd}"
            # puts "At pause #{__FILE__}-#{__LINE__}"
            # gets
            # puts "Within createNewLog E #{__FILE__}-#{__LINE__}"
            system(cmd) # moves the dutLogXXX.db to a log file record
            # puts "Within createNewLog F #{__FILE__}-#{__LINE__}"
            cmd =  "touch "+dbaseFolder+"/"+newLogFileName
            # puts cmd    # If the dutLogXXX.db does not exist, the log file will not exists either.  Therefore, 
                        # just create a dummy log file so we'll have a reference.
            # puts "Within createNewLog G #{__FILE__}-#{__LINE__}"
            system(cmd)
            # puts "Within createNewLog H #{__FILE__}-#{__LINE__}"
            # puts "at #{__FILE__}-#{__LINE__}"
            # gets # pause
            
            # Refresh the dbHandler instead.
            refreshDbHandler
            # puts "Within createNewLog I #{__FILE__}-#{__LINE__}"
            
            @logCompletedAt = getLastLogCompletedAt()
            # puts "Within createNewLog J #{__FILE__}-#{__LINE__}"
            @nextLogCreation = @logCompletedAt+@createLogInterval_UnitsInHours*60   # *60*60 converts 
                                                                                  # @createLogInterval_UnitsInHours 
                                                                                  # to seconds
            # puts "Within createNewLog K #{__FILE__}-#{__LINE__}"
            # puts "@nextLogCreation=#{@nextLogCreation} #{__FILE__}-#{__LINE__}"
        else
            # puts "Within createNewLog C #{__FILE__}-#{__LINE__}"
            # printErrorSdCardMissing()
            @db = nil
        end
        # puts "Within createNewLog D #{__FILE__}-#{__LINE__}"
    end
    
    def runSampler
        # puts "Running the sampler."
        system('cd ../"BBB_TCU Sampler"; bash runTcuSampler.sh &')
        # puts "Done executing the runTcuSampler.sh script."
        # End of 'def runSampler'
    end
    
    def GetSlotIpAddress()
    	# puts "Within 'def GetSlotIpAddress()'"
	    tbr = `ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'` # tbr - to be returned
	    return tbr[0..tbr.length-2]
    end
    
    def RunSender
        @pollIntervalInSeconds = 10 
        SharedMemory.Initialize()
        # initialize
        #
        # The goal is - the moment the new data becomes available from the sampler, that's when you start processing
        # like send data to PC for immediate display and for saving it, and saving the data into BBB local storage.
        # This way, there's lots of lee-way for recovery case something happens before the next polling.
        #
        @timeOfData = SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}")
        SendDataToPC("#{__LINE__} #{__FILE__}")
        waitTime = Time.now+@pollIntervalInSeconds
        while SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}") == @timeOfData
            sleep(0.01) 
            # puts("Data is the same!!!")
            # puts "Test RunSender G #{__FILE__}-#{__LINE__}"
            if waitTime < Time.now
                #
                # The Sampler does not seem to be updating the shared memory data.  It must be down.
                # Start the sampler process.
                #
                runSampler
            end
        end
        # puts "Test RunSender H #{__FILE__}-#{__LINE__}"
        
        waitTime = Time.now+@pollIntervalInSeconds
        sentSampledData = @timeOfData
        while true
            # puts "Test RunSender C #{__FILE__}-#{__LINE__}"
            @timeOfData = SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}")
            if (sentSampledData != @timeOfData)
                SendDataToPC("#{__LINE__}-#{__FILE__}")
                # puts "Test RunSender E #{__FILE__}-#{__LINE__}"
                sentSampledData = @timeOfData
            else
                #
                # Data is still the same?  Perhaps the sampler died?  Run the sampler.
                #
                # puts "Test RunSender G - SAMPLER DIED!!! #{__FILE__}-#{__LINE__}"
                runSampler
                # puts "Test RunSender H - RESTARTED SAMPLER #{__FILE__}-#{__LINE__}"
            end
            # puts "Test RunSender F #{__FILE__}-#{__LINE__}"
            
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
                puts "#{Time.now.inspect} Warning - time to ship data to PC and save it to local BBB dbase took"
                puts  " longer than poll interval!!!"
                # exit # - the exit code...
                #
                # waitTime = Time.now+pollInterval
            else
            	# puts "Sleeping for #{waitTime.to_f-Time.now.to_f}"
                sleep(waitTime.to_f-Time.now.to_f) 
            end
            waitTime = waitTime+@pollIntervalInSeconds
        end
    end

	def GetDataToSendPc()
        slotInfo = Hash.new()
        slotInfo[SharedLib::ConfigurationFileName] = SharedMemory.GetConfigurationFileName()
        slotInfo[SharedLib::ConfigDateUpload] = SharedMemory.GetConfigDateUpload()
        slotInfo[SharedLib::AllStepsDone_YesNo] = SharedMemory.GetAllStepsDone_YesNo()
        slotInfo[SharedLib::BbbMode] = SharedMemory.GetBbbMode()

        slotInfo[SharedLib::StepName] = SharedMemory.GetStepName()
        slotInfo[SharedLib::StepNumber] = SharedMemory.GetStepNumber()
        slotInfo[SharedLib::StepTimeLeft] = SharedMemory.GetStepTimeLeft()
        slotInfo[SharedLib::SlotTime] = @timeOfData
        slotInfo[SharedLib::AdcInput] = SharedMemory.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::MuxData] = SharedMemory.GetDataMuxData("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::Tcu] = SharedMemory.GetDataTcu("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::SlotIpAddress] = GetSlotIpAddress()
        slotInfo[SharedLib::AllStepsCompletedAt] = SharedMemory.GetAllStepsCompletedAt()
        slotInfo[SharedLib::TotalStepDuration] = SharedMemory.GetTotalStepDuration();
        slotInfoJson = slotInfo.to_json
		return slotInfoJson
	end
		
    def SendDataToPC(fromParam)
    	# puts "called from #{fromParam}"
    	slotInfoJson = GetDataToSendPc()
        puts "#{__LINE__}-#{__FILE__} slotInfoJson=#{slotInfoJson}"
        begin
            resp = 
                RestClient.post "#{SendToPc}:9292/v1/migrations/Duts", {Duts:"#{slotInfoJson}" }.to_json, :content_type => :json, :accept => :json
=begin                            
            if @timeOfData = resp.to_str
                saveDataToDb(receivedData)
            end
             => e
                e.response
=end
            rescue Exception => e  
                puts e.message  
                puts e.backtrace.inspect
        end
    end

    def nextLogCreation
        # puts "Within 'nextLogCreation' - @logCompletedAt = #{@logCompletedAt.inspect}  #{__FILE__} - #{__LINE__}"
        if @nextLogCreation.nil? && logCompletedAt != nil
            # puts "Within 'nextLogCreation' - @logCompletedAt = #{@logCompletedAt.inspect}  #{__FILE__} - #{__LINE__}"
            @nextLogCreation = logCompletedAt+@createLogInterval_UnitsInHours    # *60*60 converts 
                                                                                    # @createLogInterval_UnitsInHours 
                                                                                    # to seconds
            # End of 'if @nextLogCreation.nil?'
        end 
        return @nextLogCreation
        # End of 'nextLogCreation'
    end

    def saveDataToDb(dataToSaveParam)
        # puts "saveDataToDb got called.  #{__FILE__} - #{__LINE__}"
        # puts "dbaseFolder = '#{dbaseFolder}'  #{__FILE__} - #{__LINE__}"
        # puts "saveDataToDb A  #{__FILE__} - #{__LINE__}"
        if dbaseFolder != NO_GOOD_DBASE_FOLDER
            # puts "saveDataToDb B  #{__FILE__} - #{__LINE__}"
            timeNow = Time.now.to_i
            
    				str = "Insert into DutLog(dutData) "+
    		       "values(\"#{dataToSaveParam}\")"

            begin
                @db.execute "#{str}"
                # puts "saveDataToDb D  #{__FILE__} - #{__LINE__}"

                # puts "Total time save: #{Time.now.to_f-timeA.to_f}"
                
                # puts "nextLogCreation = #{nextLogCreation.inspect} #{__FILE__} - #{__LINE__}"
                # puts "timeNowParam = #{Time.now.inspect} #{__FILE__} - #{__LINE__}"
                if nextLogCreation.nil? == false && nextLogCreation<Time.now
                    # puts "A timeNowParam = #{Time.now.inspect} #{__FILE__} - #{__LINE__}"
                    # puts "B timeNow = #{timeNow} #{__FILE__} - #{__LINE__}"
                    #
                    # Create new log.
                    #
                    createNewLog(timeNow)
            	    # End of 'if @nextLogCreation<Time.now'
                end
    		    # puts "dbaseFolder from #{__FILE__} - #{__LINE__}"

                rescue SQLite3::Exception => e 
            		puts "#{Time.now.inspect} Exception occured"
            		puts e
            		
            		@parent.dBase = DutObj.new(@createLogInterval_UnitsInHours,@parent)
            	    # End of 'rescue SQLite3::Exception => e'
                ensure
                
                # End of 'begin' code block that will handle exceptions...
            end

            # End of 'if DutObj.dbaseFolder != NO_GOOD_DBASE_FOLDER'
        else 
            # puts "saveDataToDb C  #{__FILE__} - #{__LINE__}"
            printErrorSdCardMissing
            # puts"@parent=#{@parent}"
            # @parent.dBase = DutObj.new(@createLogInterval_UnitsInHours,@parent)
            # End of 'if DutObj.dbaseFolder != NO_GOOD_DBASE_FOLDER - ELSE'
        end
        
        # End of 'def poll()'
    end

		def printErrorSdCardMissing
			puts "Error.  SD Card Missing."
		end

    def dbaseFolder
        if @db.nil?
            #
            # Make sure the /mnt/card directory is present
            #
            mntCardDirPresent = false
            dirInMedia = Dir.entries("/mnt") 
            for folderItem in dirInMedia
                if (folderItem == "card")
                    mntCardDirPresent = true
                    break
                    # End of 'if (folderItem != "." and folderItem != "..")'
                end
                # End of 'for folderItem in dirInMedia'
            end
            
            if mntCardDirPresent == false
                #
                # The /mnt/card dir is not present.
                #
                #puts "\n\n\n The file path /mnt/card for the SD card mount is not present.  Please create the path: mkdir /mnt/card"
                # exit
                system("mkdir /mnt/card") # - This call does not work...
            end
            
            #
            # Find out if the SD Card is mounted.
            #

            isMounted = `if grep -qs '/mnt/card' /proc/mounts; then
                echo "It's mounted."
            else
                echo "It's not mounted."
            fi`
            
            isMounted = isMounted.chomp
            
            # puts "isMounted='#{isMounted}'"

            #
            # Check if dbase file exists is the SD Card
            #
            @dbaseFolder = NO_GOOD_DBASE_FOLDER
            if isMounted == ITS_MOUNTED
                @dbaseFolder = MOUNT_CARD_DIR
            else
                #
                # The card is not mounted.
                #
                # See if the SD card present.
                #
                dirInMedia = Dir.entries("/dev")
                for folderItem in dirInMedia
                    if (folderItem == "mmcblk0p1")
                        #
                        # The device is plugged in.  Mount it to /mnt/card.
                        #
                        system("mount /dev/mmcblk0p1 "+MOUNT_CARD_DIR)
                        @dbaseFolder = MOUNT_CARD_DIR
                        break
                        # End of 'if (folderItem == "mmcblk0p1")'
                    end
                    # End of 'for folderItem in dirInMedia'
                end
            end

            
            if @dbaseFolder != NO_GOOD_DBASE_FOLDER
                # puts "pause here  #{__FILE__} - #{__LINE__}"
                # gets
                #
                # SD Card is present.
                #
                
                #
                # Ensure that database table for dynamic data (status request) is present...
                #
                @statusDbFile = @dbaseFolder+"/DutLog.db"
                # puts "@statusDbFile=#{@statusDbFile}"
                # puts "pause here  #{__FILE__} - #{__LINE__}"
                # gets
                
                refreshDbHandler

                # End of 'if @dbaseFolder != NO_GOOD_DBASE_FOLDER'
            else
                # printErrorSdCardMissing(__FILE__,__LINE__)
                @db = nil
            end
            # End of 'if @db.nil?'
        end
        
        return @dbaseFolder
            
        # End of 'def dbaseFolder'
    end
    

    # This bit of magic makes it so you don't have to say
    # Migrations.instance.quantity
    # I.E. Normally to access methods that are using the Singleton
    # Gem, you have to use the itermediate accessor '.instance'
    # This ruby technique makes it so you don't have.
    # Could also be done with method_missing but this is a bit nicer
    # IMHO
    #
    class << self
      extend Forwardable
      def_delegators :instance, *SendSampledTcuToPCLib.instance_methods(false)
    end    
    
    # End of 'class SendSampledTcuToPC'
end 


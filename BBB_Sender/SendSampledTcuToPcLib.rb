# require 'sqlite3'
require 'rest_client'
require 'singleton'
require 'forwardable'
require_relative '../lib/SharedMemory'

# DRuby stuff
require 'drb/drb'
SERVER_URI="druby://localhost:8787"

class SendSampledTcuToPCLib
    include Singleton
    NO_GOOD_DBASE_FOLDER = "No good database folder"
    MOUNT_CARD_DIR = "/mnt/card"
    TOTAL_DUTS_TO_LOOK_AT = 24
    ITS_MOUNTED = "It's mounted."

    def runSampler
        # puts "Running the sampler."
        # system('cd ../"BBB_Sampler"; bash runTcuSampler.sh &')
        # puts "Done executing the runTcuSampler.sh script."
        # End of 'def runSampler'
    end
    
    def GetSlotIpAddress()
    	# puts "Within 'def GetSlotIpAddress()'"
	    tbr = `ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'` # tbr - to be returned
	    return tbr[0..tbr.length-2]
    end
    
    def RunSender
		# DRb are the two lines below
		DRb.start_service
		@sharedMemService = DRbObject.new_with_uri(SERVER_URI)
        
        lastStepNumOfSentLog = -1 # initial value

    	@dirFileRepository = "/mnt/card"
    	if Dir.exists?(@dirFileRepository) == false
    		#
    		# Run a bash command to mount the card.
    		#
    		system("umount /mnt/card") # unmount the card, case it crashes and the user # puts in a new card.
    	end
    
        loggingTime = 5 # 5 seconds for now
        pollingTime = 1 # check every second
        pollIntervalInSeconds = pollingTime
        waitTime = Time.now+pollIntervalInSeconds
        while true
            puts "Polled. #{__LINE__}-#{__FILE__}"
            sharedMem = @sharedMemService.getSharedMem()
            puts "sharedMem.GetBbbMode()='#{sharedMem.GetBbbMode()}'. #{__LINE__}-#{__FILE__}"
            if sharedMem.GetBbbMode() == SharedLib::InRunMode
                puts "Polled - in run mode #{Time.now.inspect}. #{__LINE__}-#{__FILE__}"
                if pollIntervalInSeconds == pollingTime
                    # The board started processing.
                    pollIntervalInSeconds = loggingTime
                end
                
                if lastStepNumOfSentLog != sharedMem.GetStepNumber()
                    lastStepNumOfSentLog = sharedMem.GetStepNumber()
                    puts "Sending log data.  #{Time.now.inspect}. #{__LINE__}-#{__FILE__}"

                    # tbs - to be sent                    
                    tbs  = "Test Step: step# #{sharedMem.GetStepNumber()}-#{sharedMem.GetStepName()}/n"
                    tbs += "Power Supply Setting:/n"
                    stepToWorkOn = sharedMem.getStepToWorkOn()
                    stepToWorkOn["PsConfig"].each do |key, array|
                        tbs += "key = #{key}/n"
                        tbs += "array = #{array}/n"
                    end
=begin
PS0 Setting: <voltage setting> <compliance limit> <sequence #>
<one line each for other power supplies>
Temperature Setting: <temp>
=end
                    slotInfo = Hash.new()
                    slotInfo[SharedLib::DataLog] = tbs
                    slotInfo[SharedLib::SlotOwner] = sharedMem.GetSlotOwner# GetSlotIpAddress()
                    slotInfo[SharedLib::ConfigurationFileName] = sharedMem.GetConfigurationFileName()
                    slotInfo[SharedLib::ConfigDateUpload] = sharedMem.GetConfigDateUpload()
                    sendSlotInfoToPc(slotInfoJson)
                end
            elsif sharedMem.GetBbbMode() == SharedLib::InStopMode
                # The board is done its run mode
                puts "Polled - in stop mode #{Time.now.inspect}. #{__LINE__}-#{__FILE__}"
                if pollIntervalInSeconds != pollingTime
                    pollIntervalInSeconds = pollingTime
                end
            end
            sleep(waitTime.to_f-Time.now.to_f)
            waitTime = Time.now+pollIntervalInSeconds
        end
    end

	def GetDataToSendPc(sharedMemParam)
	    if @packageInfo.nil?
	        @packageInfo = Hash.new
	    end
        slotInfo = Hash.new()
        slotInfo[SharedMemory::PsToolTip] = sharedMemParam.getPsToolTip()
        slotInfo[SharedMemory::DutToolTip] = sharedMemParam.getDutToolTip()
        waitTempMsg = sharedMemParam.getWaitTempMsg()
        if waitTempMsg.length > 0
            slotInfo[SharedMemory::WaitTempMsg] = waitTempMsg
        end
        
        if sharedMemParam.getDontSendErrorColor().nil? == false && sharedMemParam.getDontSendErrorColor() == true
            slotInfo[SharedMemory::ErrorColor] = nil
        else
            slotInfo[SharedMemory::ErrorColor] = sharedMemParam.getErrorColor() 
        end
        if sharedMemParam.GetConfiguration().nil? == false
            slotInfo[SharedMemory::LotID] = sharedMemParam.GetConfiguration()[SharedMemory::LotID]
        end
        slotInfo[SharedMemory::SlotCtrlVer] = sharedMemParam.getCodeVersion(SharedMemory::SlotCtrlVer)
        slotInfo[SharedLib::ConfigurationFileName] = sharedMemParam.GetConfigurationFileName()
        slotInfo[SharedLib::ConfigDateUpload] = sharedMemParam.GetConfigDateUpload()
        slotInfo[SharedLib::AllStepsDone_YesNo] = sharedMemParam.GetAllStepsDone_YesNo()
        slotInfo[SharedLib::BbbMode] = sharedMemParam.GetBbbMode()
        slotInfo[SharedLib::StepName] = sharedMemParam.GetStepName()
        slotInfo[SharedLib::StepNumber] = sharedMemParam.GetStepNumber()
        slotInfo[SharedLib::StepTimeLeft] = sharedMemParam.GetStepTimeLeft()
        slotInfo[SharedLib::SlotTime] = sharedMemParam.GetSlotTime("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::AdcInput] = sharedMemParam.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::MuxData] = sharedMemParam.GetDataMuxData("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::Tcu] = sharedMemParam.GetDataTcu("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::Eips] = sharedMemParam.GetDataEips()
        slotInfo[SharedLib::SlotOwner] = sharedMemParam.GetSlotOwner# GetSlotIpAddress()
        slotInfo[SharedLib::AllStepsCompletedAt] = sharedMemParam.GetAllStepsCompletedAt()
        slotInfo[SharedLib::TotalStepDuration] = sharedMemParam.GetTotalStepDuration();
        slotInfo[SharedLib::ErrorMsg] = sharedMemParam.GetErrors()
        slotInfo[SharedMemory::StopMessage] = sharedMemParam.getStopMessage()
        slotInfo[SharedLib::TotalTimeOfStepsInQueue] = sharedMemParam.GetTotalTimeOfStepsInQueue()
        # puts "A slotInfo[SharedLib::TotalTimeOfStepsInQueue] = '#{slotInfo[SharedLib::TotalTimeOfStepsInQueue]}' #{__LINE__}-#{__FILE__}"
        
        if sharedMemParam.GetButtonDisplayToNormal() != nil
            if @timesSent.nil? 
                @timesSent = 0
            end
            
            if @timesSent < 3
                @timesSent += 1
                slotInfo[SharedLib::ButtonDisplay] = sharedMemParam.GetButtonDisplayToNormal()
            else
                @timesSent = 0
                sharedMemParam.SetButtonDisplayToNormal(nil)
            end
        end
        
        @packageInfo[SharedMemory::SystemInfo] = slotInfo.to_json
		return @packageInfo
	end
	
	def sendShutDownInfo(infoParam)
	    # puts caller # Kernel#caller returns an array of strings
	    # puts "#{__LINE__}-#{__FILE__}"
	    # SharedLib.pause "infoParam='#{infoParam}'. Send shutdown info.","#{__LINE__}-#{__FILE__}"
        if @packageInfo.nil?
            @packageInfo = Hash.new
        end
        
        if @packageInfo[SharedMemory::ShutDownInfo].nil?
            @packageInfo[SharedMemory::ShutDownInfo] = Array.new
        end
        
        @packageInfo[SharedMemory::ShutDownInfo].push(infoParam)
	end
	
	def sendLoggerPart(loggerData)
        if @packageInfo.nil?
            @packageInfo = Hash.new
        end
        
        if @packageInfo[SharedMemory::LogInfo].nil?
            @packageInfo[SharedMemory::LogInfo] = Array.new
        end
        
        @packageInfo[SharedMemory::LogInfo].push(loggerData)
	end
	
    def SendDataToPC(sharedMemParam,fromParam)
    	# puts "called from #{fromParam}"
    	slotInfoJson = GetDataToSendPc(sharedMemParam)
    	# Clear any error listed in the memomry
        sharedMemParam.ClearErrors() # This frees up some bytes in the shared memory.
        
=begin
    	# Save data into dbase if sharedMemParam.GetAllStepsDone_YesNo() == SharedLib::No && 
    	# sharedMemParam.GetBbbMode() == SharedLib::InRunMode
        if sharedMemParam.GetAllStepsDone_YesNo() == SharedLib::No && sharedMemParam.GetBbbMode() == SharedLib::InRunMode
            # The data needs to be logged in...
            dBaseFileName = sharedMemParam.GetDBaseFileName()
            if dBaseFileName.nil? == false && dBaseFileName.length > 0
                # puts "\n\n\nA Checking #{@dirFileRepository}/#{sharedMemParam.GetDBaseFileName()} sharedMemParam.GetDBaseFileName().length = #{sharedMemParam.GetDBaseFileName().length}  #{__LINE__}-#{__FILE__}"
                # There's a valid dBase file name to save the data.
                # puts "B Checking #{@dirFileRepository}/#{@dBaseFileName} #{__LINE__}-#{__FILE__}"
            	if @dBaseFileName != dBaseFileName
            	    @dBaseFileName = dBaseFileName
            	    @db = SQLite3::Database.open "#{@dirFileRepository}/#{@dBaseFileName}"
            	end
            	
            	
            	forDbase = SharedLib.ChangeDQuoteToSQuoteForDbFormat(slotInfoJson)
            	
    	        str = "Insert into log(idLogTime, data) "+
        		       "values(#{timeOfData},\"#{forDbase}\")"
    
                begin
                    @db.execute "#{str}"
                    rescue SQLite3::Exception => e 
                        puts "\n\n"
                		SharedLib.bbbLog "str = ->#{str}<- #{__LINE__}-#{__FILE__}"
                		SharedLib.bbbLog "#{e} #{__LINE__}-#{__FILE__}"
                	    # End of 'rescue SQLite3::Exception => e'
                    ensure
                    
                    # End of 'begin' code block that will handle exceptions...
                end        	
            end
        end
=end
    	

        # puts "#{__LINE__}-#{__FILE__} slotInfoJson=#{slotInfoJson}"
        json = slotInfoJson.to_json
        sendSlotInfoToPc(json)
    end    
    
    def sendSlotInfoToPc(newSlotInfoJson)
        # SharedLib.pause "Function got called.  Checking value @firstBackLog='#{@firstBackLog}'","#{__LINE__}-#{__FILE__}"
        # puts "@firstBackLog check"
        # puts @firstBackLog
        if File.exist?(SharedLib::PathFile_BbbBackLog)
			File.open(SharedLib::PathFile_BbbBackLog, "r") do |f|
				f.each_line do |line|
				    if @firstBackLog.nil?
    					@firstBackLog = line
    					break
    				end
				end
			end
        end
        # puts "@firstBackLog check 2"
        # puts @firstBackLog
        # SharedLib.pause "Checking if backlog file was opened.","#{__LINE__}-#{__FILE__}"

        if @pcIpAddr.nil?
    		File.open("../BBB_configuration files/ethernet scheme setup.csv", "r") do |f|
    			f.each_line do |line|
    			    if line[0..1] == "PC"
    			        @pcIpAddr = line[3..-1].chomp
    			        
    			    end
    				if @pcIpAddr.nil? == false
    				    # We got an IP address
    				    break
    				end
    			end
    		end
            if @pcIpAddr.nil?
                @samplerData.ReportError("File 'BBB_configuration files/ethernet scheme setup.csv' does not have an entry for PC IP address.")
            end
        end
        
        if @arrOfDataToSend.nil?
            @arrOfDataToSend = Array.new
        end
        
        @arrOfDataToSend.push(newSlotInfoJson)

        if @xCountPassedThenSendAgain.nil? || @xCountPassedThenSendAgain >= 5
            puts "Sending slotCtrl data to PC (#{@pcIpAddr}) #{__LINE__}-#{__FILE__}."
            @xCountPassedThenSendAgain = 0
        end
        @xCountPassedThenSendAgain += 1
        while @arrOfDataToSend.length > 0
            slotInfoJson = @arrOfDataToSend.shift
            ct = 0
            sentData = false
            while sentData == false && ct < 1
                begin
                    if @firstBackLog.nil?
                        begin
                            # puts "Sending slotInfoJson"
                            # puts slotInfoJson
                            resp = 
                                RestClient.post "#{@pcIpAddr}:9292/v1/migrations/Duts", {Duts:"#{slotInfoJson}" }.to_json, :content_type => :json, :accept => :json
                            sentData = true
                            @packageInfo = nil
                            rescue Exception => e  
                                puts "Failed to send to '#{@pcIpAddr}'.  Attempting again."
=begin                                
                                puts e.message  
                                @firstBackLog = slotInfoJson
                        	    File.open(SharedLib::PathFile_BbbBackLog, "a") { 
                        	        |file| file.write(slotInfoJson)
                        	        file.write "\n"
                                }
=end                                
                        end
                    else
                        begin
                            # puts "Sending @firstBackLog"
                            # puts @firstBackLog
                            resp = 
                                RestClient.post "#{@pcIpAddr}:9292/v1/migrations/Duts", {Duts:"#{@firstBackLog}" }.to_json, :content_type => :json, :accept => :json

                            # it was a good send.  Get all the backlog and send it to the pc for consumption
                            arr = Array.new
                            ct = 0
                			File.open(SharedLib::PathFile_BbbBackLog, "r") do |f|
                				f.each_line do |line|
                				    if ct>0
                                        arr.push(line) 
                                    end
                                    #puts "derived line=#{line}"
                                    ct += 1
                				end
                			end
                			# SharedLib.pause "ct='#{ct}' Checking saved data.","#{__LINE__}-#{__FILE__}"
                            # Add the latest data into the array
                            arr.push(slotInfoJson) 
                            @packageInfo = Hash.new
                            @packageInfo["BackLogData"] = arr
                            begin
                                resp = 
                                    RestClient.post "#{@pcIpAddr}:9292/v1/migrations/Duts", {Duts:"#{@packageInfo.to_json}" }.to_json, :content_type => :json, :accept => :json
                                # SharedLib.pause "asdf","#{__LINE__}-#{__FILE__}"
                                @packageInfo = nil
                                # SharedLib.pause "asdf","#{__LINE__}-#{__FILE__}"
                                sentData = true
                                # SharedLib.pause "asdf","#{__LINE__}-#{__FILE__}"
                                `rm -rf /mnt/card/PcDown.BackLog`
                                # SharedLib.pause "Finally deleted the backlog file.","#{__LINE__}-#{__FILE__}"
                                # SharedLib.pause "PcDown.BackLog got deleted.","#{__LINE__}-#{__FILE__}"
                                @firstBackLog = nil
                                rescue Exception => e  
                                    @firstBackLog = arr[0]
                                    @packageInfo = nil
                            end
                            rescue Exception => e  
                                puts "Failed to send to '#{@pcIpAddr}'.  Attempting again."
                                puts e.message  
                                # puts e.backtrace.inspect
=begin                                
                        	    File.open(SharedLib::PathFile_BbbBackLog, "a") { 
                        	        |file| file.write(slotInfoJson)
                        	        file.write "\n"
                                }
=end                                
                        end
                    end
                end
                ct += 1
            end
            
            if sentData == false
                puts "Completely failed to send.  Saving data to PcDown.BackLog file."
                if @firstBackLog.nil?
                    @firstBackLog = slotInfoJson
                end
                @packageInfo = nil
        	    File.open(SharedLib::PathFile_BbbBackLog, "a") { 
        	        |file| file.write(slotInfoJson) 
        	        file.write "\n"
                }
            end
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

	def printErrorSdCardMissing
		puts "Error.  SD Card Missing."
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

# working 224

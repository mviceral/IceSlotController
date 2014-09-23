#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryExtension.so'
require_relative '../lib/SharedLib'
#require 'singleton'
#require 'forwardable'
require 'json'
require 'pp'

# V1 - version 1
# Adding the mode of the BBB

class SharedMemory 
    include SharedMemoryExtension
#    include Singleton
    
    Mode = "Mode"
    Cmd = "Cmd"
    CmdProcessed = "CmdProcessed"
    
    TimeOfPcUpload = "TimeOfPcUpload"
    TimeOfPcLastCmd = "TimeOfPcLastCmd"
    SlotOwner = "SlotOwner"    

    def writeAndFreeLocked(strParam, fromParam)
        if @lockedAt == ""
            puts "Memory not locked!  Called from [ #{fromParam} ]"
            exit
        end
	    @lockedAt = ""
        # puts "Freeing locked memory. #{__LINE__}-#{__FILE__}"
        # @theMemory = strParam.to_json
        @theMemory = strParam
        # puts "Check A. #{__LINE__}-#{__FILE__}"
        # puts "Check B. #{__LINE__}-#{__FILE__}"
    end
    
=begin    
    def freeLocked(fromParam)
        # sourceLock - not used but for making sure data is considered.
        if @lockedAt == ""
            puts "Memory not locked!  Called from [ #{fromParam} ]"
            exit
        end
	    @lockedAt = ""
    end
=end

    def getMemory()
        while @lockedAt.nil? == false && @lockedAt != ""
            puts "It's locked at #{@lockedAt}"
            sleep(1)
        end
        
        begin
            # ds = JSON.parse(@theMemory)
            if @theMemory.nil?
                @theMemory = Hash.new
            end
            ds = @theMemory
            rescue
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            writeAndFreeLocked(ds, "#{__LINE__}-#{__FILE__}")
        end
        return ds
    end
    
    def lockMemory(fromParam)
        # puts "Locking memory (from:#{fromParam}). #{__LINE__}-#{__FILE__}"
    	while @lockedAt.nil? == false && @lockedAt != ""
            puts "Shared memory used at '#{@lockedAt}'."
            sleep(1.0/1000.0)
            # puts "Called from '#{fromParam}'."
            # puts "Exiting code. @#{__LINE__}-#{__FILE__}"
            # exit
    	end
    	
    	@lockedAt = fromParam
        begin
        	# puts "From #{__LINE__}-#{__FILE__}"
        	# puts "GetDataV1()=#{GetDataV1()}"
        	# ds = JSON.parse(@theMemory)
        	if @theMemory.nil?
        	    @theMemory = Hash.new
        	end
        	ds = @theMemory
                    	
        	# puts "A - good data #{__LINE__}-#{__FILE__}"
        rescue
            ds = Hash.new
            puts "\n\n\nB - faulty data #{__LINE__}-#{__FILE__}"
        end	    
        return ds
    end


    #
    # Known functions of SharedMemoryExtension
    #
    def getPCShared()
	ds = getMemory()
        if ds[SharedLib::PC].nil?
        	ds = lockMemory("#{__LINE__}-#{__FILE__}")
        	ds[SharedLib::PC] = Hash.new
        	writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        end
        return ds[SharedLib::PC]
    end
    
	def SetDispBoardData(configurationFileNameParam, configDateUploadParam, allStepsDone_YesNoParam, bbbModeParam,
		stepNameParam, stepNumberParam, stepTotalTimeParam, slotTimeParam, slotOwnerParam, allStepsCompletedAtParam, dispTotalStepDurationParam, adcInputParam, muxDataParam, tcuParam,eipsParam, errMsgParam,totalTimeOfStepsInQueue)      
		# puts "tcuParam = #{}"
		# SharedLib.pause "Checking tcuParam", "#{__LINE__}-#{__FILE__}"
		ds = lockMemory("#{__LINE__}-#{__FILE__}")
		if ds[SharedLib::PC].nil?
			ds[SharedLib::PC] = Hash.new
		end
		if slotOwnerParam.nil? == false && slotOwnerParam.length > 0
			if ds[SharedLib::PC][slotOwnerParam].nil?
				ds[SharedLib::PC][slotOwnerParam] = Hash.new
			end

			ds[SharedLib::PC][slotOwnerParam][SharedLib::TotalTimeOfStepsInQueue] = totalTimeOfStepsInQueue 
			ds[SharedLib::PC][slotOwnerParam][SharedLib::ConfigurationFileName] = configurationFileNameParam 
			ds[SharedLib::PC][slotOwnerParam][SharedLib::ConfigDateUpload] = configDateUploadParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::AllStepsDone_YesNo] = allStepsDone_YesNoParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::BbbMode] = bbbModeParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::StepName] = stepNameParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::StepNumber] = stepNumberParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::StepTimeLeft] = stepTotalTimeParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::SlotTime] = slotTimeParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::AllStepsCompletedAt] = allStepsCompletedAtParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::TotalStepDuration] = dispTotalStepDurationParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::AdcInput] = adcInputParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::MuxData] = muxDataParam
			ds[SharedLib::PC][slotOwnerParam][SharedLib::Eips] = eipsParam

			if tcuParam.nil? == false && tcuParam.length > 0
				tcuData = tcuParam
				datArr = Array.new
				ct = 1
				while ct<tcuData.split('|').length
					datArr.push(tcuData.split('|')[ct])
					ct += 1
				end

				hash = Hash.new
				ct = 0
				while ct<datArr.length
					hold = datArr[ct].split('@')
					hash[hold[0]] = hold[1]
					ct += 1
				end
				ds[SharedLib::PC][slotOwnerParam][SharedLib::Tcu] = hash
			end

			if errMsgParam.nil? == false
				# There were some errors from the board.
				# Write the error into a log file
				newErrLogFileName = "../NewErrors_#{slotOwnerParam}.log"
				while errMsgParam.length>0
					errItem = errMsgParam.shift
					File.open(newErrLogFileName, "a") { 
						|file| file.write("#{errItem.to_json}\n") 
					}
				end
			end

			writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
		end
	end

	def GetDispTotalTimeOfStepsInQueue(slotOwnerParam)
		return getMemory()[SharedLib::PC][slotOwnerParam][SharedLib::TotalTimeOfStepsInQueue]
	end

	def GetDispButton(slotOwnerParam)
		return getMemory()[SharedLib::PC][slotOwnerParam][SharedLib::ButtonDisplay]
	end

	def SetDispButton(slotOwnerParam,toDisplay)
		ds = lockMemory("#{__LINE__}-#{__FILE__}")
		ds[SharedLib::PC][slotOwnerParam][SharedLib::ButtonDisplay] = toDisplay
		writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}");
	end
	def GetDispErrorMsg(slotOwnerParam)
		# Display what ever un-acknowledged errors are in the record.
		pcShared = getPCShared()
		slotOwner = slotOwnerParam
		if pcShared[slotOwner].nil? == false && pcShared[slotOwner][SharedLib::ErrorMsg].nil?
			newErrLogFileName = "../NewErrors_#{slotOwner}.log"
			errorItem = `head -1 #{newErrLogFileName}`
			#puts "errorItem='#{errorItem}' #{__LINE__}-#{__FILE__}"
			if errorItem.length > 0
				ds = lockMemory("#{__LINE__}-#{__FILE__}")
				ds[SharedLib::PC][slotOwner][SharedLib::ErrorMsg] = JSON.parse(errorItem)
				writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
			end
		end

		if pcShared[slotOwner].nil? || pcShared[slotOwner][SharedLib::ErrorMsg].nil?
			return ""
		end
		errItem = pcShared[slotOwner][SharedLib::ErrorMsg]
		return "&nbsp;&nbsp;#{Time.at(errItem[1]).inspect} - #{errItem[0]}"
	end

	def GetDispStepTimeLeft(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::StepTimeLeft]
	end

	def GetDispAdcInput(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::AdcInput]
	end
	
	def GetDispMuxData(slotOwnerParam)
		# puts "slotOwnerParam=#{slotOwnerParam} #{__LINE__}-#{__FILE__}"
		slotOwner = getPCShared()[slotOwnerParam]
		if slotOwner.nil?
			return ""
		end
		return slotOwner[SharedLib::MuxData]
	end
	
	def GetDispTcu(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::Tcu]
	end

	def GetDispAllStepsCompletedAt(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::AllStepsCompletedAt]
	end

	def GetDispEips(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		if getPCShared()[slotOwnerParam][SharedLib::Eips].nil?
			return Hash.new
		end
		return getPCShared()[slotOwnerParam][SharedLib::Eips]
	end

=begin
	def GetDispSlotOwner()
		if getPCShared()[SlotOwner].nil?
			return ""
		end
		return getPCShared()[SlotOwner]
	end
=end
	
	def SetDispSlotOwner(slotOwnerParam)
    		ds = lockMemory("#{__LINE__}-#{__FILE__}")
			if ds[SharedLib::PC].nil?
				ds[SharedLib::PC] = Hash.new
			end
			if ds[SharedLib::PC][slotOwnerParam].nil? 
				ds[SharedLib::PC][slotOwnerParam] = Hash.new
			end
			ds[SharedLib::PC][SlotOwner] = slotOwnerParam
			writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
	end		
	def GetDispConfigurationFileName(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::ConfigurationFileName]
    end
    
	def GetDispConfigDateUpload(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::ConfigDateUpload]
    end
    
    def GetDispAllStepsDone_YesNo(slotOwnerParam)
		hold = getPCShared()[slotOwnerParam]
		if hold.nil? || hold[SharedLib::AllStepsDone_YesNo].nil?
			return ""
		end
		return hold[SharedLib::AllStepsDone_YesNo]
    end
    
    def GetDispBbbMode(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::BbbMode]
    end
    
    def GetDispStepName(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::StepName]
    end
    
    def GetDispStepNumber(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::StepNumber]
    end

	def GetDispTotalStepDuration(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::TotalStepDuration]
	end
	
	def GetDispSlotTime(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::SlotTime]
	end
	 
	def GetDispSlotIpAddress(slotOwnerParam)
		if getPCShared()[slotOwnerParam].nil?
			return ""
		end
		return getPCShared()[slotOwnerParam][SharedLib::SlotIpAddress]
	end
		
    def SetAllStepsCompletedAt(allStepsCompletedAtParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::AllStepsCompletedAt] = allStepsCompletedAtParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end

    def GetAllStepsCompletedAt()
        return getMemory()[SharedLib::AllStepsCompletedAt]
    end

    def GetSlotTime(fromParam)
        # puts "A GetSlotTime got called. #{fromParam} @#{__LINE__}-#{__FILE__}"
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        # puts "B GetSlotTime got called. #{fromParam} @#{__LINE__}-#{__FILE__}"
        return ds[SharedLib::SlotTime]
    end
    
    def SetSlotTime(slotTimeParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::SlotTime] = slotTimeParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepTimeLeft
    	return getMemory()[SharedLib::StepTimeLeft]
    end 
    
    def SetStepTimeLeft(stepTotalTimeParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::StepTimeLeft] = stepTotalTimeParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepName()
        return getMemory()[SharedLib::StepName]
    end
    
    def SetStepName(stepNameParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::StepName] = stepNameParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepNumber()
        return getMemory()[SharedLib::StepNumber]
    end
    
    def SetStepNumber(stepNumberParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::StepNumber] = stepNumberParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetTimeOfPcUpload()
        return lockMemory("#{__LINE__}-#{__FILE__}")[TimeOfPcUpload]
    end
    
    def GetConfiguration()
        return getMemory()["Configuration"]
    end
    
    def pause(paramA,fromParam)
        puts "Paused - '#{paramA}' '#{fromParam}'"
        gets
    end

    def SetConfigurationFileName(configurationFileNameParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::ConfigurationFileName] = configurationFileNameParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end

    def GetConfigurationFileName()
        return getMemory()[SharedLib::ConfigurationFileName]
    end

    def GetDBaseFileName()    
        return lockMemory("#{__LINE__}-#{__FILE__}")[SharedLib::DBaseFileName]
    end
    
    def SetDBaseFileName(dBaseFileName)    
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::DBaseFileName] = dBaseFileName
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
        
    def GetConfigDateUpload()
        return getMemory()[SharedLib::ConfigDateUpload]
    end
    
    def SetConfigDateUpload(configDateUploadParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        # puts "configDateUploadParam=#{configDateUploadParam} #{__LINE__}-#{__FILE__}"
        ds[SharedLib::ConfigDateUpload] = configDateUploadParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end

	def SetDataBoardToPc(hashParam)
		hash = hashParam
    
		if hash[SharedLib::ButtonDisplay].nil? == false
			ds = lockMemory("#{__LINE__}-#{__FILE__}")
			ds[SharedLib::PC][hash[SharedLib::SlotOwner]][SharedLib::ButtonDisplay] = hash[SharedLib::ButtonDisplay]
			writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
		end

		SetDispBoardData(
			hash[SharedLib::ConfigurationFileName],
			hash[SharedLib::ConfigDateUpload],
			hash[SharedLib::AllStepsDone_YesNo],
			hash[SharedLib::BbbMode],
			hash[SharedLib::StepName],
			hash[SharedLib::StepNumber],
			hash[SharedLib::StepTimeLeft],
			hash[SharedLib::SlotTime],
			hash[SharedLib::SlotOwner],
			hash[SharedLib::AllStepsCompletedAt],
			hash[SharedLib::TotalStepDuration],
			hash[SharedLib::AdcInput],
			hash[SharedLib::MuxData],
			hash[SharedLib::Tcu],
			hash[SharedLib::Eips],
			hash[SharedLib::ErrorMsg],
			hash[SharedLib::TotalTimeOfStepsInQueue])
	end

    def SetAllStepsDone_YesNo(allStepsDone_YesNoParam,fromParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        #if allStepsDone_YesNoParam == SharedLib::Yes
        #    pause "Bingo! Called from #{fromParam}","#{__LINE__}-#{__FILE__}"
        #end
        ds[SharedLib::AllStepsDone_YesNo] = allStepsDone_YesNoParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetAllStepsDone_YesNo()
        return getMemory()[SharedLib::AllStepsDone_YesNo]
    end

    def ClearConfiguration(fromParam)
        # puts "called from #{fromParam}"
        puts "Start 'def ClearConfiguration' #{__LINE__} #{__FILE__}"
        SetConfigurationFileName("")
        SetConfigDateUpload("")
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
    	ds["Configuration"] = "" # Clears the configuration.
    	ds[TimeOfPcUpload] = Time.new.to_i
        tbr = writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}") # tbr - to be returned
        SetTimeOfPcLastCmd(Time.new.to_i,"#{__LINE__}-#{__FILE__}")
        puts "Done 'def ClearConfiguration' #{__LINE__} #{__FILE__}"
    end
    
    def GetTotalStepDuration()
        ds = getMemory()
        if ds["Configuration"].nil?
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            ds["Configuration"] = Hash.new
            
            if ds["Configuration"][SharedLib::TotalStepDuration].nil?
                ds["Configuration"][SharedLib::TotalStepDuration] = ""
            end
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        end
        return ds["Configuration"][SharedLib::TotalStepDuration]
    end
    
    def GetSlotOwner()
        return getMemory()["SlotOwner"]
    end
    
    def SetSlotOwner(slotOwnerParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds["SlotOwner"] = slotOwnerParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
        
    def SetConfiguration(dataParam,fromParam)
        configDataUpload = dataParam["ConfigDateUpload"]
        configurationFileName = dataParam["FileName"]
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[TimeOfPcUpload] = Time.new.to_i
        hold = dataParam
        #
        # Setup the TotalTimeLeft in the steps, and make sure that the variables for TimeOfRun
        # are initialized per step also.
        # 
        totalStepDuration = 0
        if hold.nil? == false
            hold["Steps"].each do |key, array|
                puts "E #{__LINE__}-#{__FILE__}"
                hold["Steps"][key]["StepTimeLeft"] = 60.0*hold["Steps"][key]["Step Time"].to_f
                totalStepDuration += hold["Steps"][key]["StepTimeLeft"]
            end
        end
        ds["Configuration"] = hold
        ds["Configuration"][SharedLib::TotalStepDuration] = totalStepDuration
        ds[SharedLib::ConfigDateUpload] = configDataUpload
    	ds[SharedLib::ConfigurationFileName] = configurationFileName
        configDateUpload = Time.at(configDataUpload.to_i)
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        
    	dBaseFileName = "#{configDateUpload.strftime("%Y%m%d_%H%M%S")}_#{GetConfigurationFileName()}.db"
    	
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::DBaseFileName] = dBaseFileName
        db = SQLite3::Database.new( "/mnt/card/#{ds[SharedLib::DBaseFileName]}" )
        if db.nil?
            SharedLib.bbbLog "db is nil. #{__LINE__}-#{__FILE__}"
        else
            SharedLib.bbbLog "Creating table. #{__LINE__}-#{__FILE__}"
                db.execute("create table log ("+
            "idLogTime int, data TEXT"+     # 'dutNum' the dut number reference of the data
            ");")
        end
        ds["SlotOwner"] = hold["SlotOwner"]
        tbr = writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        return tbr
        rescue
    end
    
    def Initialize()
	@lockedAt = ""
        InitializeSharedMemory()
    end
    
    def initialize()
        #   - This function initialized the shared memory variables.  If not called, the functions below will be rendered 
        #   useless.
        InitializeSharedMemory()
    end 
    
    def ClearErrors()
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        if ds[SharedLib::ErrorMsg].nil? == false
            ds[SharedLib::ErrorMsg] = nil
        end
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetErrors()    
        ds = getMemory()
        if ds[SharedLib::ErrorMsg].nil?
            return ""
        else
            return ds[SharedLib::ErrorMsg]
        end
    end

    def ReportError(errMsgParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        if ds[SharedLib::ErrorMsg].nil?
            ds[SharedLib::ErrorMsg] = Array.new
        end
        
        errItem = Array.new
        errItem.push(errMsgParam)
        errItem.push(Time.new.to_i)
        
        ds[SharedLib::ErrorMsg].push(errItem)
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def PopPcCmd()
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        tbr = ds[Cmd].shift # tbr - to be returned
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        return tbr
    end
    
	def GetPcCmd()
	    pcCmd = getMemory()[Cmd]
	    if pcCmd.class.to_s == "Array"
            return pcCmd
        else
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            ds[Cmd] = Array.new
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
            return ds[Cmd];
	    end
	end
	
    def SetPcCmdThread(cmdParam,timeOfCmdParam)
        ds = getMemory()
        if ds[Cmd].nil? || ds[Cmd].class.to_s != "Array"
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            ds[Cmd] = Array.new
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        end
        
        samplerNotProcessed = true
        while samplerNotProcessed
            # Put the command and the time stamp of command in one object.
            arrItem = Array.new
            arrItem.push(cmdParam)
            arrItem.push(timeOfCmdParam)
            
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            ds[Cmd].push(arrItem)
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
            
            totalCmdInStack = ds[Cmd].length
            puts "Total sent cmds in stack: '#{totalCmdInStack}'"
    
            while ds[Cmd].length == totalCmdInStack
                sleep(0.25)
                ds = getMemory()
                puts "x Total sent cmds in stack: '#{ds[Cmd].length}'"
            end
            
            # The sampler processed the command.  Make sure it was the last command sent.
            
            if ds[CmdProcessed].nil? == false && ds[CmdProcessed].length > 0 && ds[CmdProcessed][0] == cmdParam  && ds[CmdProcessed][1] == timeOfCmdParam
                samplerNotProcessed = false
                puts "Processed the command: '#{ds[CmdProcessed][0]}'"
            #else
                # Keep looping until the board processed it.
            end
        end
    end
	
    def SetPcCmd(cmdParam,calledFrom)
        t1=Thread.new{SetPcCmdThread(cmdParam,Time.now.to_i)}
    end

	def GetBbbMode()
        return getMemory()[Mode]
    end

    def SetTimeOfPcLastCmd(timeOfPcLastCmdParam,fromParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[TimeOfPcLastCmd] = timeOfPcLastCmdParam
        tbr = writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        return tbr
    end
    
    def GetTimeOfPcLastCmd()
        if getMemory()[TimeOfPcLastCmd].nil?
            SetTimeOfPcLastCmd(0,"#{__LINE__}-#{__FILE__}")
        end
        return getMemory()[TimeOfPcLastCmd]
    end

    def SetBbbMode(modeParam,calledFrom)
        # puts "param sent #{modeParam}"
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        oldModeParam = ds[Mode]
        print "Changing bbb mode from #{oldModeParam} to "
        ds[Mode] = "#{modeParam}"
        puts "#{modeParam} [#{calledFrom}]"
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end

    def GetDataMuxData(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	tbr = getMemory()[SharedLib::MuxData] # tbr - to be returned
    	if tbr.nil?
    	    ds = lockMemory("#{__LINE__}-#{__FILE__}")
    		ds[SharedLib::MuxData] = Hash.new()
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    	    tbr = ds[SharedLib::MuxData] # tbr - to be returned
    	end
        return tbr
    end
    
    def GetDataAdcInput(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	ds = getMemory()
    	if ds[SharedLib::AdcInput].nil?
    	    ds = lockMemory("#{__LINE__}-#{__FILE__}")
    		ds[SharedLib::AdcInput] = Hash.new()
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    	end
        return ds[SharedLib::AdcInput]
    end

	
    def GetDataV1() # Changed function so other calls to it will fail and have to adhere to the new data structure
        #   - Gets the data sitting in the shared memory.
        #   - If it returns "", the function InitializeSharedMemory() is probably not called, or there is no data.
        return GetDataFromSharedMemory()
    end
    
    def GetDataGpio
        return getMemory()[SharedLib::Gpio]
    end
    
    def WriteDataGpio(stringParam, fromParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        if ds[SharedLib::Gpio].nil?
            ds[SharedLib::Gpio] = Hash.new
        end
        
        ds[SharedLib::Gpio] = stringParam 
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetDataEips()
        return getMemory()[SharedLib::Eips]
    end
    
    def WriteDataEips(stringParam,fromParam)
        # Eips = Ethernet I (Current) PS
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        if ds[SharedLib::Eips].nil?
            ds[SharedLib::Eips] = Hash.new
        end
        
        ds[SharedLib::Eips] = stringParam 
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetDataTcu(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	tbr = getMemory()[SharedLib::Tcu] # tbr - to be returned
    	if tbr.nil?
    	    ds = lockMemory("#{__LINE__}-#{__FILE__}")
    		ds[SharedLib::Tcu] = Hash.new()
            writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    	    tbr = ds[SharedLib::Tcu]
    	end
        return tbr
    end

    
    def WriteDataTcu(stringParam,fromParam)
        puts "stringParam='#{stringParam}' fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        if ds[SharedLib::Tcu].nil?
            ds[SharedLib::Tcu] = Hash.new
        end
        
        ds[SharedLib::Tcu] = stringParam 
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        puts "Check = '#{GetDataTcu("#{__LINE__}-#{__FILE__}")}'  #{__LINE__}-#{__FILE__}"
    end

    def SetupData
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        
        if ds[SharedLib::AdcInput].nil?
            ds[SharedLib::AdcInput] = Hash.new
        end

        if ds[SharedLib::MuxData].nil?
            ds[SharedLib::MuxData] = Hash.new
        end

        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
    end

	def SetButtonDisplayToNormal(buttonDispParam)
		ds = lockMemory("#{__LINE__}-#{__FILE__}")
		ds[SharedLib::ButtonDisplay] = buttonDispParam
		writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}");		
	end

	def GetButtonDisplayToNormal()
		return getMemory()[SharedLib::ButtonDisplay]
	end

    def SetTotalTimeOfStepsInQueue(dataParam)
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        ds[SharedLib::TotalTimeOfStepsInQueue] = dataParam
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}");		
    end
    
    def GetTotalTimeOfStepsInQueue()
		ds = getMemory()
		if ds[SharedLib::TotalTimeOfStepsInQueue].nil?
            ds = lockMemory("#{__LINE__}-#{__FILE__}")
            ds[SharedLib::TotalTimeOfStepsInQueue] = 0
		    writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}");		
		end
		return ds[SharedLib::TotalTimeOfStepsInQueue]
    end
    
    def SetData(dataTypeParam,indexParam,dataValueParam,multiplierParam)
        # puts "check A #{__LINE__}-#{__FILE__}"
        ds = lockMemory("#{__LINE__}-#{__FILE__}")
        # puts "check B #{__LINE__}-#{__FILE__}"
        if ds[dataTypeParam].nil?
            # puts "ds[#{dataTypeParam}] is nil #{__LINE__}-#{__FILE__}"
            ds[dataTypeParam] = Hash.new
        end
        # puts "check C #{__LINE__}-#{__FILE__}"
        
        ds[dataTypeParam][indexParam.to_s] = (dataValueParam*multiplierParam[indexParam]).to_s
        writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
        # puts "check D #{__LINE__}-#{__FILE__}"
        # PP.pp(ds)
        # puts "@setData.length=#{@setData.length}"
        # gets
        # puts "writeAndFreeLocked(@setData) = #{writeAndFreeLocked(@setData)}"
    end
    
=begin    
    class << self
      extend Forwardable
      def_delegators :instance, *instance_methods(false)
    end
=end    
end
# 638

#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryExtension.so'
require_relative '../lib/SharedLib'
require 'singleton'
require 'forwardable'
require 'json'
require 'pp'

# V1 - version 1
# Adding the mode of the BBB

class SharedMemory 
    include SharedMemoryExtension
    include Singleton
    
    Mode = "Mode"
    Cmd = "Cmd"
    
    TimeOfPcUpload = "TimeOfPcUpload"
    TimeOfPcLastCmd = "TimeOfPcLastCmd"
    
    #
    # Known functions of SharedMemoryExtension
    #
    def getPCShared()
        ds = getDS()
        if ds[SharedLib::PC].nil?
        	ds[SharedLib::PC] = Hash.new
        end
        return ds[SharedLib::PC]
    end
    
    def SetDispBoardData(configurationFileNameParam, configDateUploadParam, allStepsDone_YesNoParam, bbbModeParam,
      stepNameParam, stepNumberParam, stepTotalTimeParam, slotTimeParam, slotIpAddressParam, allStepsCompletedAtParam,dispTotalStepDurationParam, 
      adcInputParam, muxDataParam, tcuParam)      
    	ds = getDS()
    	if ds[SharedLib::PC].nil?
      	ds[SharedLib::PC] = Hash.new
      end
      
      ds[SharedLib::PC][SharedLib::ConfigurationFileName] = configurationFileNameParam 
      ds[SharedLib::PC][SharedLib::ConfigDateUpload] = configDateUploadParam
      ds[SharedLib::PC][SharedLib::AllStepsDone_YesNo] = allStepsDone_YesNoParam
      ds[SharedLib::PC][SharedLib::BbbMode] = bbbModeParam
      ds[SharedLib::PC][SharedLib::StepName] = stepNameParam
      ds[SharedLib::PC][SharedLib::StepNumber] = stepNumberParam
      ds[SharedLib::PC][SharedLib::StepTotalTime] = stepTotalTimeParam
      ds[SharedLib::PC][SharedLib::SlotTime] = slotTimeParam
      ds[SharedLib::PC][SharedLib::SlotIpAddress] = slotIpAddressParam
      ds[SharedLib::PC][SharedLib::AllStepsCompletedAt] = allStepsCompletedAtParam
      ds[SharedLib::PC][SharedLib::TotalStepDuration] = dispTotalStepDurationParam
      ds[SharedLib::PC][SharedLib::AdcInput] = adcInputParam
      ds[SharedLib::PC][SharedLib::MuxData] = muxDataParam
      ds[SharedLib::PC][SharedLib::Tcu] = tcuParam
      WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
	end


	def GetDispAdcInput()
		return getPCShared()[SharedLib::AdcInput]
	end
	
	def GetDispMuxData()
		return getPCShared()[SharedLib::MuxData]
	end
	
	def GetDispTcu()
		return getPCShared()[SharedLib::Tcu]
	end

	def GetDispAllStepsCompletedAt
		return getPCShared()[SharedLib::AllStepsCompletedAt]
	end
		
    def GetDispConfigurationFileName
			return getPCShared()[SharedLib::ConfigurationFileName]
    end
    
    def GetDispConfigDateUpload
			return getPCShared()[SharedLib::ConfigDateUpload]
    end
    
    def GetDispAllStepsDone_YesNo
			return getPCShared()[SharedLib::AllStepsDone_YesNo]
    end
    
    def GetDispBbbMode
			return getPCShared()[SharedLib::BbbMode]
    end
    
    def GetDispStepName
			return getPCShared()[SharedLib::StepName]
    end
    
    def GetDispStepNumber
			return getPCShared()[SharedLib::StepNumber]
    end

	def GetDispStepTotalTime
		return getPCShared()[SharedLib::StepTotalTime]
	end
	
	def GetDispTotalStepDuration
		return getPCShared()[SharedLib::TotalStepDuration]
	end
	
	def GetDispSlotTime
		return getPCShared()[SharedLib::SlotTime]
	end
	 
	def GetDispSlotIpAddress
		return getPCShared()[SharedLib::SlotIpAddress]
	end
		
    def GetDispSlotTime()
        return getPCShared()[SharedLib::SlotTime]
    end
    
    def SetAllStepsCompletedAt(allStepsCompletedAtParam)
        ds = getDS()
        ds[SharedLib::AllStepsCompletedAt] = allStepsCompletedAtParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end

    def GetAllStepsCompletedAt()
        return getDS[SharedLib::AllStepsCompletedAt]
    end

    def GetSlotTime(fromParam)
        return getDS[SharedLib::SlotTime]
    end
    
    def SetSlotTime(slotTimeParam)
        ds = getDS()
        ds[SharedLib::SlotTime] = slotTimeParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepTimeLeft
    	return getDS()[SharedLib::StepTimeLeft]
    end 
    
    def SetStepTimeLeft(stepTotalTimeParam)
        ds = getDS()
        ds[SharedLib::StepTimeLeft] = stepTotalTimeParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepName()
        return getDS()[SharedLib::StepName]
    end
    
    def SetStepName(stepNameParam)
        ds = getDS()
        ds[SharedLib::StepName] = stepNameParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetStepNumber()
        return getDS()[SharedLib::StepNumber]
    end
    
    def SetStepNumber(stepNumberParam)
        ds = getDS()
        ds[SharedLib::StepNumber] = stepNumberParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetTimeOfPcUpload()
        return getDS()[TimeOfPcUpload]
    end
    
    def GetConfiguration()
        return getDS()["Configuration"]
    end
    
    def pause(paramA,fromParam)
        puts "Paused - '#{paramA}' '#{fromParam}'"
        gets
    end

    def SetConfigurationFileName(configurationFileNameParam)
        ds = getDS()
        ds[SharedLib::ConfigurationFileName] = configurationFileNameParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end

    def GetConfigurationFileName()
        return getDS()[SharedLib::ConfigurationFileName]
    end
    
    def SetConfigDateUpload(configDateUploadParam)
        ds = getDS()
        puts "configDateUploadParam=#{configDateUploadParam} #{__LINE__}-#{__FILE__}"
        ds[SharedLib::ConfigDateUpload] = configDateUploadParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end

	def	SetDataBoardToPc(hashParam)
		# hash = JSON.parse(hashParam)
		hash = hashParam
		# PP.pp(hash)
		SetDispBoardData(
			hash[SharedLib::ConfigurationFileName],
			hash[SharedLib::ConfigDateUpload],
			hash[SharedLib::AllStepsDone_YesNo],
			hash[SharedLib::BbbMode],
			hash[SharedLib::StepName],
			hash[SharedLib::StepNumber],
			hash[SharedLib::StepTotalTime],
			hash[SharedLib::SlotTime],
			hash[SharedLib::SlotIpAddress],
			hash[SharedLib::AllStepsCompletedAt],
			hash[SharedLib::TotalStepDuration],
			hash[SharedLib::AdcInput],
			hash[SharedLib::MuxData],
			hash[SharedLib::Tcu]
			)
	end

    def GetConfigDateUpload()
        return getDS()[SharedLib::ConfigDateUpload]
    end
    
    def SetAllStepsDone_YesNo(allStepsDone_YesNoParam)
        ds = getDS()
        ds[SharedLib::AllStepsDone_YesNo] = allStepsDone_YesNoParam
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def GetAllStepsDone_YesNo()
        return getDS()[SharedLib::AllStepsDone_YesNo]
    end

    def ClearConfiguration(fromParam)
    	puts "called from #{fromParam}"
      puts "Start 'def ClearConfiguration' #{__LINE__} #{__FILE__}"
    	SharedMemory.SetConfigurationFileName("")
    	SharedMemory.SetConfigDateUpload("")
    	ds = getDS()
    	ds["Configuration"] = "" # Clears the configuration.
    	ds[TimeOfPcUpload] = Time.new.to_i
      tbr = WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}") # tbr - to be returned
      SetTimeOfPcLastCmd(Time.new.to_i,"#{__LINE__}-#{__FILE__}")
      puts "Done 'def ClearConfiguration' #{__LINE__} #{__FILE__}"
    end
    
    def GetTotalStepDuration()
        ds = getDS()
        if ds["Configuration"].nil?
            ds["Configuration"] = Hash.new
            
            if ds["Configuration"][SharedLib::TotalStepDuration].nil?
                ds["Configuration"][SharedLib::TotalStepDuration] = ""
            end
            WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
        end
        return ds["Configuration"][SharedLib::TotalStepDuration]
    end
        
    def SetConfiguration(dataParam,fromParam)
        ds = getDS()
        puts "SetConfiguration got called #{fromParam}"
        puts "A Within 'SetConfiguration' getDS()[TimeOfPcUpload] = #{getDS()[TimeOfPcUpload]} #{__LINE__}-#{__FILE__}"
        ds[TimeOfPcUpload] = Time.new.to_i
        puts "A.1 #{__LINE__}-#{__FILE__}"
        hold = JSON.parse(dataParam)
        puts "A.2 #{__LINE__}-#{__FILE__}"
        #
        # Setup the TotalTimeLeft in the steps, and make sure that the variables for TimeOfRun
        # are initialized per step also.
        # 
        # PP.pp(hold["Steps"])
        totalStepDuration = 0
        hold["Steps"].each do |key, array|
            puts "A.3 #{__LINE__}-#{__FILE__}"
            hold["Steps"][key]["TotalTimeLeft"] = 60.0*hold["Steps"][key]["Step Time"].to_f
            totalStepDuration += hold["Steps"][key]["TotalTimeLeft"]
            puts "hold[\"Steps\"][key][\"TotalTimeLeft\"] = #{hold["Steps"][key]["TotalTimeLeft"]}"
            puts "hold[\"Steps\"][key][\"StepTime\"] = #{hold["Steps"][key]["Step Time"]}"
            # puts "hold[#{Steps}][#{key}][#{TimeOfRun}] = #{hold[Steps][key][TimeOfRun]}"
        end
        puts "A.4 #{__LINE__}-#{__FILE__}"
        # pause("Checking contents of steps within SetConfiguration function.","#{__LINE__}-#{__FILE__}")
        
        
        ds["Configuration"] = hold
        ds["Configuration"][SharedLib::TotalStepDuration] = totalStepDuration
        puts "A.5 #{__LINE__}-#{__FILE__}"
        tbr = WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}") # tbr - to be returned        
        SharedMemory.SetConfigDateUpload(SharedMemory.GetConfiguration()["ConfigDateUpload"])
        SharedMemory.SetConfigurationFileName(SharedMemory.GetConfiguration()["FileName"])
        puts "A.6 #{__LINE__}-#{__FILE__}"
        puts "B Within 'SetConfiguration' getDS()[TimeOfPcUpload] = #{getDS()[TimeOfPcUpload]} #{__LINE__}-#{__FILE__}"
        SetTimeOfPcLastCmd(Time.new.to_i,"#{__LINE__}-#{__FILE__}")
        return tbr
        rescue
    end
    
    def Initialize()
        #   - This function initialized the shared memory variables.  If not called, the functions below will be rendered 
        #   useless.
        InitializeSharedMemory()
    end 

	def GetPcCmd()
        return getDS()[Cmd]
	end
	
    def SetPcCmd(cmdParam,calledFrom)
        # puts "param sent #{cmdParam}"
        oldCmdParam = getDS()[Cmd]
        print "Changing bbb mode from #{oldCmdParam} to "
        ds = getDS()
        ds[Cmd] = "#{cmdParam}"
        puts "#{cmdParam} [#{calledFrom}]"
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
        SetTimeOfPcLastCmd(Time.new.to_i,"#{__LINE__}-#{__FILE__}")        
    end
	
	def GetBbbMode()
        return getDS()[Mode]
    end
    
    def getDS() 
        #
        # Get the DS - data structure
        #
        # puts "fromParam=#{fromParam}"
        begin
        	# puts "From #{__LINE__}-#{__FILE__}"
        	# puts "GetDataV1()=#{GetDataV1()}"
        	ds = JSON.parse(GetDataV1()) # ds = data structure.
        	# puts "A - good data #{__LINE__}-#{__FILE__}"
        rescue
          ds = Hash.new
          puts "B - faulty data #{__LINE__}-#{__FILE__}"
        end
        return ds
    end


    def SetTimeOfPcLastCmd(timeOfPcLastCmdParam,fromParam)
        ds = getDS()
        ds[TimeOfPcLastCmd] = timeOfPcLastCmdParam
        tbr = WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
        return tbr
    end
    
    def GetTimeOfPcLastCmd()
        if getDS()[TimeOfPcLastCmd].nil?
            SetTimeOfPcLastCmd(0,"#{__LINE__}-#{__FILE__}")
        end
        return getDS()[TimeOfPcLastCmd]
    end

    def SetBbbMode(modeParam,calledFrom)
        # puts "param sent #{modeParam}"
        ds = getDS()
        oldModeParam = ds[Mode]
        print "Changing bbb mode from #{oldModeParam} to "
        ds[Mode] = "#{modeParam}"
        puts "#{modeParam} [#{calledFrom}]"
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end

    def GetDataMuxData(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	tbr = getDS()[SharedLib::MuxData] # tbr - to be returned
    	if tbr.nil?
    		tbr = Hash.new()
    	end
        return tbr
    end
    
    def GetDataAdcInput(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	tbr = getDS()[SharedLib::AdcInput] # tbr - to be returned
    	if tbr.nil?
    		tbr = Hash.new()
    	end
        return tbr
    end

	
    def GetDataTcu(fromParam)
        # puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
    	tbr = getDS()[SharedLib::Tcu] # tbr - to be returned
    	if tbr.nil?
    		tbr = Hash.new()
    	end
        return tbr
    end

    def GetDataV1() # Changed function so other calls to it will fail and have to adhere to the new data structure
        #   - Gets the data sitting in the shared memory.
        #   - If it returns "", the function InitializeSharedMemory() is probably not called, or there is no data.
        return GetDataFromSharedMemory()
    end
    
    def WriteData(stringParam,fromParam)
        puts "fromParam = #{fromParam} #{__LINE__}-#{__FILE__}"
        ds = getDS()
        if ds[SharedLib::Tcu].nil?
            ds[SharedLib::Tcu] = Hash.new
        end
        
        ds[SharedLib::Tcu] = stringParam 
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def WriteDataV1(stringParam, fromParam) # Changed function so other calls to it will fail and have to adhere to the new data 
                                # structure
        #   - Writes data to the shared memory.
        #       return values:
        #       0 - no error writing to memory.
        #       1 - not initialized.  Run the function InitializeVariables(), first.
        #       2 - sent String too long.  Not all data written in.
        # puts "WriteDataV1 called from #{fromParam} #{__LINE__}-#{__FILE__}"
        # puts "stringParam = #{stringParam}"
        tbr = WriteDataToSharedMemory(stringParam)
        return tbr
    end 
    
    def DoneSettingData() 
        # Write the value of @setData into shared memory
    end
    
    def SetupData
        ds = getDS()
        if ds[SharedLib::AdcInput].nil?
            puts "Got in B #{__LINE__}-#{__FILE__}"
            ds[SharedLib::AdcInput] = Hash.new
        end

        if ds[SharedLib::MuxData].nil?
            puts "Got in C #{__LINE__}-#{__FILE__}"
            ds[SharedLib::MuxData] = Hash.new
        end

        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
    end
    
    def SetData(dataTypeParam,indexParam,dataValueParam,multiplierParam)
        ds = getDS()
        if ds[dataTypeParam].nil?
            puts "ds[#{dataTypeParam}] is nil #{__LINE__}-#{__FILE__}"
            ds[dataTypeParam] = Hash.new
        end
        
        ds[dataTypeParam][indexParam.to_s] = (dataValueParam*multiplierParam[indexParam]).to_s
        WriteDataV1(ds.to_json,"#{__LINE__}-#{__FILE__}")
        # PP.pp(ds)
        # puts "@setData.length=#{@setData.length}"
        # gets
        # puts "WriteDataV1(@setData.to_json) = #{WriteDataV1(@setData.to_json)}"
    end
    
    class << self
      extend Forwardable
      def_delegators :instance, *SharedMemory.instance_methods(false)
    end
end

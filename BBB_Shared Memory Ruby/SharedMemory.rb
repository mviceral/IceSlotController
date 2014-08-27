#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryExtension.so'
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
    Data = "Data"
    Cmd = "Cmd"
    
    TimeOfPcUpload = "TimeOfPcUpload"
    TimeOfPcLastCmd = "TimeOfPcLastCmd"
    
    #
    # Known functions of SharedMemoryExtension
    #
    def GetTimeOfPcUpload()
        return getDS()[TimeOfPcUpload]
    end
    
    def GetConfiguration()
        return getDS()[Configuration]
    end
    
    def pause(paramA,fromParam)
        puts "Paused - '#{paramA}' '#{fromParam}'"
        gets
    end
    
    def SetConfiguration(dataParam,fromParam)
        ds = getDS()
        ds[TimeOfPcUpload] = Time.new.to_i
        hold = JSON.parse(dataParam)
        #
        # Setup the TotalTimeLeft in the steps, and make sure that the variables for TimeOfRun, and TimeOfStop
        # are initialized per step also.
        # 
        hold[Steps].each do |key, array|
            hold[Steps][key][TotalTimeLeft] = hold[Steps][key][StepTime].to_i
            hold[Steps][key][TimeOfStop] = Time.now.to_i
            hold[Steps][key][TimeOfRun] = hold[Steps][key][TimeOfStop]
            # puts "hold[#{Steps}][#{key}][#{TotalTimeLeft}] = #{hold[Steps][key][TotalTimeLeft]}"
            # puts "hold[#{Steps}][#{key}][#{TimeOfStop}] = #{hold[Steps][key][TimeOfStop]}"
            # puts "hold[#{Steps}][#{key}][#{TimeOfRun}] = #{hold[Steps][key][TimeOfRun]}"
        end
        # pause("Checking contents of steps within SetConfiguration function.","#{__LINE__}-#{__FILE__}")
        
        ds[Configuration] = hold
        tbr = WriteDataV1(ds.to_json) # tbr - to be returned
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
        WriteDataV1(ds.to_json)
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
            ds = JSON.parse(GetDataV1()) # ds = data structure.
            # puts "A - good data #{__LINE__}-#{__FILE__}"
        rescue
            ds = Hash.new
            # puts "B - faulty data #{__LINE__}-#{__FILE__}"
        end
        return ds
    end


    def SetTimeOfPcLastCmd(timeOfPcLastCmdParam,fromParam)
        ds = getDS()
        ds[TimeOfPcLastCmd] = timeOfPcLastCmdParam
        tbr = WriteDataV1(ds.to_json)
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
        WriteDataV1(ds.to_json)
    end
	
    def GetData()
        return getDS()[Data]
    end

    def GetDataV1() # Changed function so other calls to it will fail and have to adhere to the new data structure
        #   - Gets the data sitting in the shared memory.
        #   - If it returns "", the function InitializeSharedMemory() is probably not called, or there is no data.
        return GetDataFromSharedMemory()
    end
    
    def WriteData(stringParam)
        ds = getDS()
        ds[Data] = stringParam 
        WriteDataV1(ds.to_json)
    end
    
    def WriteDataV1(stringParam) # Changed function so other calls to it will fail and have to adhere to the new data 
                                # structure
        #   - Writes data to the shared memory.
        #       return values:
        #       0 - no error writing to memory.
        #       1 - not initialized.  Run the function InitializeVariables(), first.
        #       2 - sent String too long.  Not all data written in.
        return WriteDataToSharedMemory(stringParam)
    end 
    
    class << self
      extend Forwardable
      def_delegators :instance, *SharedMemory.instance_methods(false)
    end
end


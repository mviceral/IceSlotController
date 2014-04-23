#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryExtension.so'
require 'singleton'
require 'forwardable'
require 'json'

# V1 - version 1
# Adding the mode of the BBB

class SharedMemory 
    include SharedMemoryExtension
    include Singleton
    
    Mode = "Mode"
    Data = "Data"
    
    InRunMode = "InRunMode"
    InStopMode = "InStopMode"
    InIdleMode = "InIdleMode"
    SequenceUp = "SequenceUp"
    SequenceDown = "SequenceDown"
    
    TimeOfPcUpload = "TimeOfPcUpload"
    Configuration = "Configuration"
    TimeOfPcLastCmd = "TimeOfPcLastCmd"
    
    #
    # Known functions of SharedMemoryExtension
    #
    def SetTimeOfPcLastCmd(timeOfPcLastCmdParam)
        getDS()[TimeOfPcLastCmd] = timeOfPcLastCmdParam
        return WriteDataV1(getDS().to_json)
    end
    
    def GetTimeOfPcLastCmd()
        return getDS()[TimeOfPcLastCmd]
    end
    
    def GetTimeOfPcUpload()
        return getDS()[TimeOfPcUpload]
    end
    
    def GetConfiguration()
        return JSON.parse(getDS()[Configuration])
    end
    
    def SetConfiguration(dataParam)
        getDS()[TimeOfPcUpload] = Time.new.to_i
        getDS()[Configuration] = dataParam
        SetTimeOfPcLastCmd(Time.new.to_i)
        return WriteDataV1(getDS().to_json)
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
        puts "param sent #{cmdParam}"
        oldCmdParam = getDS()[Cmd]
        print "Changing bbb mode from #{oldCmdParam} to "
        getDS()[Cmd] = "#{cmdParam}"
        puts "#{cmdParam} [#{calledFrom}]"
        SetTimeOfPcLastCmd(Time.new.to_i)
        return WriteDataV1(getDS().to_json)
    end
	
	def GetBbbMode()
        return getDS()[Mode]
    end
    
    def getDS() 
        #
        # Get the DS - data structure
        #
        if @ds.nil?
            begin
                @ds = JSON.parse(GetDataV1()) # ds = data structure.
            rescue
                @ds = Hash.new
            end
        end
        return @ds
    end

    def SetBbbMode(modeParam,calledFrom)
        puts "param sent #{modeParam}"
        oldModeParam = getDS()[Mode]
        print "Changing bbb mode from #{oldModeParam} to "
        getDS()[Mode] = "#{modeParam}"
        puts "#{modeParam} [#{calledFrom}]"
        SetTimeOfPcLastCmd(Time.new.to_i)
        return WriteDataV1(getDS().to_json)
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
        getDS()[Data] = stringParam 
        WriteDataV1(getDS().to_json)
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


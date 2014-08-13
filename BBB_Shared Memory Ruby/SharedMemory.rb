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
    
    SequenceUp = "SequenceUp"
    SequenceDown = "SequenceDown"
    
    #
    # Known functions of SharedMemoryExtension
    #
    def Initialize()
        #   - This function initialized the shared memory variables.  If not called, the functions below will be rendered 
        #   useless.
        InitializeSharedMemory()
    end 

    def GetMode()
        ds = JSON.parse(GetDataV1()) # ds = data structure.
        return ds[Mode]
    end
    
    def getDS() 
        #
        # Get the DS - data structure
        #
        begin
            ds = JSON.parse(GetDataV1()) # ds = data structure.
        rescue
            ds = Hash.new
        end
        return ds
    end

    def SetMode(modeParam)
        getDS()[Mode] = modeParam
        WriteDataV1(getDS().to_json)
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


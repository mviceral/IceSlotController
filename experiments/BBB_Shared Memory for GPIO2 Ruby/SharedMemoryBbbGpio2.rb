#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryBbbGpio2Extension.so'
# require 'singleton'
# require 'forwardable'

class SharedMemoryBbbGpio2 
    include SharedMemoryBbbGpio2Extension
#    include Singleton
    
    #
    # Known functions of SharedMemoryExtension
    #
    def initialize()
        #   - This function initialized the shared memory variables.  If not called, the functions below will be rendered 
        #   useless.
        InitializeSharedMemory()
    end 

    def getDS() 
        #
        # Get the DS - data structure
        #
        # puts "fromParam=#{fromParam}"
        # puts GetDataV1()
        begin
            ds = JSON.parse(GetDataV1()) # ds = data structure.
            # puts "A getDS()"
        rescue
            ds = Hash.new
            # puts "B getDS()"
        end
        return ds
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
=begin
    class << self
      extend Forwardable
      def_delegators :instance, *SharedMemoryGpio2.instance_methods(false)
    end
=end
end


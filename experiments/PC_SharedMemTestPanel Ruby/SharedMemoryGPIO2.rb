#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryExtensionGpio2.so'
# require 'singleton'
# require 'forwardable'

class SharedMemoryGpio2 
    include SharedMemoryExtensionGpio2
#    include Singleton
    
    #
    # Known functions of SharedMemoryExtension
    #
    def initialize()
        #   - This function initialized the shared memory variables.  If not called, the functions below will be rendered 
        #   useless.
        # puts "SharedMemoryGpio2 got called.  Within Initialize()."
        InitializeSharedMemory()
    end 

    def GetData()
        #   - Gets the data sitting in the shared memory.
        #   - If it returns "", the function InitializeSharedMemory() is probably not called, or there is no data.
        return GetDataFromSharedMemory()
    end
    
    def WriteData(stringParam)
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


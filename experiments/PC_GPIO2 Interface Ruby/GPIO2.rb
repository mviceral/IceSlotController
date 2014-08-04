#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'Port2Interface.so'
require_relative '../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryGPIO2.rb'
require 'rest_client'
require 'json'

#@Removed comment to run on real machine
# require 'singleton'
# require 'forwardable'


class GPIO_PC
# include Singleton
  
  def initialize
    @emulatorEnabled = true
  	@sharedGpio2 = SharedMemoryGpio2.new
  	fromSharedMem = @sharedGpio2.GetData()
  	if fromSharedMem[0.."BbbShared".length-1] != "BbbShared"
  	  #
  	  # The Shared memory is not initialized.  Set it up.
  	  #
  		parsed = Hash.new
  		@sharedGpio2.WriteData("BbbShared"+parsed.to_json)
  	end
  	# End of 'def initialize'
  end 
  
  def setGPIO2(addrParam, dataParam)
  	# Write to shared mem
		fromSharedMem = @sharedGpio2.GetData()
		parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
		parsed[addrParam.to_s] = dataParam
    @response = 
      RestClient.post 
        "http://192.168.7.2:8000/v1/BbbSetter/", 
        {Registers:"#{parsed}" }.to_json, 
        :content_type => :json, 
        :accept => :json
	  returnedValue = @sharedGpio2.WriteData("BbbShared"+@response)
	  # End of 'def setGPIO2(addrParam, dataParam)'
  end
  
  def getGPIO2(addrParam)
  	fromSharedMem = @sharedGpio2.GetData()
  	if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
  		# The shared memory has some legit data in it.
  		parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
  		parsed.each do |key, array|
  	end  		
  end
  
    # End of 'class GPIO2'
end

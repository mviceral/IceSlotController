#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative '../PC_SharedMemTestPanel Ruby/SharedMemoryGPIO2'
require 'rest_client'
require 'json'

#@Removed comment to run on real machine
# require 'singleton'
# require 'forwardable'


class PcGpio
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
    @response = RestClient.post "http://192.168.7.2:7000/v1/bbbsetter/", 
    {addr:"#{addrParam}", data:"#{dataParam}" }.to_json, :content_type => :json, :accept => :json
	  returnedValue = @sharedGpio2.WriteData("BbbShared"+@response)
	  # End of 'def setGPIO2(addrParam, dataParam)'
  end
  
  def getGPIO2(addrParam)
  	# puts "getGPIO2, addrParam=#{addrParam}"
  	fromSharedMem = @sharedGpio2.GetData()
  	# puts "fromSharedMem=#{fromSharedMem}"
  	parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
  	# puts "parsed=#{parsed}"
  	toBeReturned = parsed[addrParam.to_i(16).to_i.to_s]
  	# puts "toBeReturned.class=#{toBeReturned.class}, toBeReturned=#{toBeReturned}"
  	return toBeReturned
  end
  # End of 'class GPIO2'
end


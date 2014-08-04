#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'Port2Interface.so'
require_relative '../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryGPIO2.rb'
require 'json'

#@Removed comment to run on real machine
require 'beaglebone'
# require 'singleton'
# require 'forwardable'


class GPIO2
#@Removed 2 comment to run on real machine
include Beaglebone
include Port2Interface
# include Singleton
  
  def initialize
#@Removed comment to run on real machine
  GPIOPin.new(:P8_45, :IN) 
  GPIOPin.new(:P8_46, :IN) 
  GPIOPin.new(:P8_43, :IN) 
  GPIOPin.new(:P8_44, :IN) 
  GPIOPin.new(:P8_41, :IN) 
  GPIOPin.new(:P8_42, :IN) 
  GPIOPin.new(:P8_39, :IN) 
  GPIOPin.new(:P8_40, :IN) 

#@Removed comment to run on real machine
    initPort2()
    
    # Shared memory for emulator.
    @emulatorEnabled = true
	@sharedGpio2 = SharedMemoryGpio2.new
	fromSharedMem = @sharedGpio2.GetData()
	if fromSharedMem[0.."BbbShared".length-1] != "BbbShared"
		parsed = Hash.new
		@sharedGpio2.WriteData("BbbShared"+parsed.to_json)
	end
	# End of 'def initialize'
  end 
  
  def setBitOff(addrParam, dataParam)
      
  end
  
  def setBitOn(addrParam, dataParam)
  end
  
  def setGPIO2(addrParam, dataParam)
  	# Write to shared mem
		fromSharedMem = @sharedGpio2.GetData()
		parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
		# file = File.open("/tmp/setGPIO.txt", 'a')
		# file.write("setGPIO2: addrParam=#{addrParam}, addrParam.class=#{addrParam.class}, dataParam=#{dataParam}\n")
		if @emulatorEnabled
			# file.write("@emulatorEnabled is true.\n") 
  		parsed[addrParam.to_s] = dataParam
  		returnedValue = @sharedGpio2.WriteData("BbbShared"+parsed.to_json)
  		# file.write("returnedValue = '#{returnedValue}'.\n")
		end
#@Removed comment to run on real machine
    sendToPort2(addrParam,dataParam)
      # End of 'def setGPIO2(addrParam, dataParam)'
  end
  
  def getGPIO2(addrParam)
  		# write to emulator
  		# file = File.open("/tmp/setGPIO.txt", 'a') 
  		# file.write("Within 'def getGPIO2(addrParam)'.\n");
  		# file.write("addrParam.class=#{addrParam.class}\n");
  		if @emulatorEnabled
			fromSharedMem = @sharedGpio2.GetData()
			if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
				#  The shared memory has some legit data in it.
				# settings.sharedMem += "After trimming out the tag: '#{fromSharedMem["BbbShared".length..-1]}'.<br>"
				# file.write("Shared memory is enabled.\n");
				parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
				parsed.each do |key, array|
					# file.write("#{key}----- key.class='#{key.class}'")
					# file.write("array='#{array}'")						
				end  		
				# file.write("parsed = '#{parsed}'\n") 
				# file.write("getGPIO2: addrParam=#{addrParam}  parsed[addrParam.to_s]=#{parsed[addrParam.to_s]}.\n") 
			else
				# file.write("Shared memory is NOT enabled.");
				parsed = Hash.new
			end
			# file.write("getGPIO2: addrParam=#{addrParam}, addrParam.class='#{addrParam.class}' parsed[addrParam]=#{parsed[addrParam]}.\n") 
	  		return parsed[addrParam.to_s]
	  	else
#@Removed comment to run on real machine
            return getFromPort2(addrParam)
  	end
  end
  
  def getImagesOf16Addrs
      #
      # This function must get called first and must be called all the time to get the latest values of the 
      # registers
      #
      getImagesOf16AddrsGPIO2
  end
  
  #
  # The following are the addresses of the registered names, along with their items
  #
  SLOT_ADDR_x0        = 0x0
      # For Reading
      # Gives 4 slots
      # Gives you up to 64 systems - just basically get the whole value vice broken to little bits checking each
      # state of bits.
      #
      # Scenario
      # Step 1 , gets this address, assigns to the IP address of BBB.
      # Config file must be available for the frist 3 address for the IP of the BBB.
      #
      X0_Reset            = 0x01  # Write to reset.
      
  LED_STAT_x1         = 0x1
      # Needs to be a X1_LEDEN = 1 to have the rest have a purpose.  For debugging.
      X1_LEDEN            = 0x80
      X1_LED3             = 0x08
      X1_LED2             = 0x04
      X1_LED1             = 0x02
      X1_LED0             = 0x01
      
  EXT_INPUTS_x2       = 0x2
      # Bitwise function, look for a 1 indicating that it's been activated (capture).
      # Mainly reading bitwise
      # XOR bit masking
      X2_FANT2B           = 0x80
      X2_FANT2A           = 0x40
      X2_FANT1B           = 0x20
      X2_FANT1A           = 0x10
      X2_SENSR2           = 0x08
      X2_SENSR1           = 0x04
      X2_USRSW2           = 0x02
      X2_USRSW1           = 0x01
      # Writing - to clear the above bits.
      # After reading, write the clear to reset all the bits.
      # (Capture compare function)
      X2_CLEAR            = 0x01
      
  PS_ENABLE_x3        = 0x3
      # For power supply sequencing.
      # Bitwise for mainly for writing.
      # XOR bit masking
      X3_P12V             = 0x40
      X3_N5V              = 0x20
      X3_P5V              = 0x10
      X3_PS6              = 0x08
      X3_PS8              = 0x04
      X3_PS9              = 0x02
      X3_PS10             = 0x01
      
  EXT_SLOT_CTRL_x4    = 0x4
      # Bitwise for mainly for writing.
      # XOR bit masking
      X4_POWER            = 0x80
      X4_FAN1             = 0x20
      X4_FAN2             = 0x10
      X4_BUZR             = 0x08
      X4_LEDRED           = 0x04
      X4_LEDYEL           = 0x02
      X4_LEDGRN           = 0x01
      
  SLOT_FAN_PWM_x5     = 0x5
      # Mostly for setting, - write the whole byte.
      
  ETS_ALM1_x6         = 0x6
      # Bitwise only for reading.
      # TCU alarm 
      X6_ALM7             = 0x80
      X6_ALM6             = 0x40
      X6_ALM5             = 0x20
      X6_ALM4             = 0x10
      X6_ALM3             = 0x08
      X6_ALM2             = 0x04
      X6_ALM1             = 0x02
      X6_ALM0             = 0x01

  ETS_ALM2_x7         = 0x7
      # Bitwise only for reading.
      X7_ALM15            = 0x80
      X7_ALM14            = 0x40
      X7_ALM13            = 0x20
      X7_ALM12            = 0x10
      X7_ALM11            = 0x08
      X7_ALM10            = 0x04
      X7_ALM9             = 0x02
      X7_ALM8             = 0x01

  ETS_ALM3_x8         = 0x8
      # Bitwise only for reading.
      X8_ALM23            = 0x80
      X8_ALM22            = 0x40
      X8_ALM21            = 0x20
      X8_ALM20            = 0x10
      X8_ALM19            = 0x08
      X8_ALM18            = 0x04
      X8_ALM17            = 0x02
      X8_ALM16            = 0x01

  ETS_ENA1_x9         = 0x9
      # Bitwise mainly for writing.
      # XOR bit mask
      X9_ETS7             = 0x80
      X9_ETS6             = 0x40
      X9_ETS5             = 0x20
      X9_ETS4             = 0x10
      X9_ETS3             = 0x08
      X9_ETS2             = 0x04
      X9_ETS1             = 0x02
      X9_ETS0             = 0x01

  ETS_ENA2_xA         = 0xA
      # Bitwise mainly for writing.
      # XOR bit mask
      XA_ETS15            = 0x80
      XA_ETS14            = 0x40
      XA_ETS13            = 0x20
      XA_ETS12            = 0x10
      XA_ETS11            = 0x08
      XA_ETS10            = 0x04
      XA_ETS09            = 0x02
      XA_ETS08            = 0x01

  ETS_ENA3_xB         = 0xB
      # Bitwise mainly for writing.
      # XOR bit mask
      XB_ETS23            = 0x80
      XB_ETS22            = 0x40
      XB_ETS21            = 0x20
      XB_ETS20            = 0x10
      XB_ETS19            = 0x08
      XB_ETS18            = 0x04
      XB_ETS17            = 0x02
      XB_ETS16            = 0x01

  ETS_RX_SEL_xC       = 0xC
      # Just a number from 0 to 23, mostly writing
      # The TCU (temp controller unit)

  ANA_MEAS4_SEL_xD    = 0xD
      # Just a number from 0 to 48, mostly writing
      # The item to measure analog channel 4.
  
  def getRegValue (addrParam, itemParam)
      #
      # Use the following constants for addrParam
      #
      method_getRegValueGPIO2
  end
  
  def testWithScope
      puts "Running function 'testWithScope'.  Make sure to plug in scope onto BBB that shows the signals on the"
      puts "ADDR and DATA pins."
      initialize
      addr = 0
      data = 0
      while true
          if addr<15
              addr = addr+1
          else
              addr = 0
          end
      
          if data<255
              data = data+1
          else
              data = 0
          end
          a = getFromPort2(addr)
          # puts "a=#{a}"
      end
      # End of 'def testWithScope'
  end

=begin    
    class << self
      extend Forwardable
      def_delegators :instance, *GPIO2.instance_methods(false)
    end    
=end
    # End of 'class GPIO2'
end

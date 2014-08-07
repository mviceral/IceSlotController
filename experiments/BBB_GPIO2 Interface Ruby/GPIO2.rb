#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'Port2Interface.so'
require_relative "../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryBbbGpio2"
require 'json'
require 'socket'      # Sockets are in standard library


#@Removed comment to run on real machine
require 'beaglebone'
# require 'singleton'
# require 'forwardable'


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
  R0_SYS7              = 0x80   # Read bit Sys7
  R0_SYS6              = 0x40   # Read bit Sys6
  R0_SYS5              = 0x20   # Read bit Sys5
  R0_SYS4              = 0x10   # Read bit Sys4
  R0_SYS3              = 0x08   # Read bit Sys3
  R0_SYS2              = 0x04   # Read bit Sys2
  R0_SYS1              = 0x02   # Read bit Sys1
  R0_SYS0              = 0x01   # Read bit Sys0
  W0_Reset             = 0x01   # Write to reset.
  
LED_STAT_x1         = 0x1
  # Needs to be a X1_LEDEN = 1 to have the rest have a purpose.  For debugging.
  W1_LEDEN            = 0x80    
  X1_LED3             = 0x08
  X1_LED2             = 0x04
  X1_LED1             = 0x02
  X1_LED0             = 0x01
  
EXT_INPUTS_x2       = 0x2
  # Bitwise function, look for a 1 indicating that it's been activated (capture).
  # Mainly reading bitwise
  # XOR bit masking
  R2_FANT2B           = 0x80
  R2_FANT2A           = 0x40
  R2_FANT1B           = 0x20
  R2_FANT1A           = 0x10
  R2_SENSR2           = 0x08
  R2_SENSR1           = 0x04
  R2_USRSW2           = 0x02
  R2_USRSW1           = 0x01
  # Writing - to clear the above bits.
  # After reading, write the clear to reset all the bits.
  # (Capture compare function)
  W2_CLEAR            = 0x01
  
PS_ENABLE_x3        = 0x3
  # For power supply sequencing.
  # Bitwise for mainly for writing.
  # XOR bit masking
  W3_P12V             = 0x40
  W3_N5V              = 0x20
  W3_P5V              = 0x10
  W3_PS6              = 0x08
  W3_PS8              = 0x04
  W3_PS9              = 0x02
  W3_PS10             = 0x01
  
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
  R6_ALM7             = 0x80
  R6_ALM6             = 0x40
  R6_ALM5             = 0x20
  R6_ALM4             = 0x10
  R6_ALM3             = 0x08
  R6_ALM2             = 0x04
  R6_ALM1             = 0x02
  R6_ALM0             = 0x01

ETS_ALM2_x7         = 0x7
  # Bitwise only for reading.
  R7_ALM15            = 0x80
  R7_ALM14            = 0x40
  R7_ALM13            = 0x20
  R7_ALM12            = 0x10
  R7_ALM11            = 0x08
  R7_ALM10            = 0x04
  R7_ALM9             = 0x02
  R7_ALM8             = 0x01

ETS_ALM3_x8         = 0x8
  # Bitwise only for reading.
  R8_ALM23            = 0x80
  R8_ALM22            = 0x40
  R8_ALM21            = 0x20
  R8_ALM20            = 0x10
  R8_ALM19            = 0x08
  R8_ALM18            = 0x04
  R8_ALM17            = 0x02
  R8_ALM16            = 0x01

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
    puts "initializing @regValues #{__LINE__}-#{__FILE__}"
    @regValues = Hash.new
    @sharedBbbGpio2 = SharedMemoryBbbGpio2.new
  	fromSharedMem = @sharedBbbGpio2.GetData()
  	if fromSharedMem[0.."BbbShared".length-1] != "BbbShared"
        #
        # The Shared memory is not initialized.  Set it up.
        #
        puts "A.1 Initializing shared mem in BBB."
        parsed = Hash.new
        @sharedBbbGpio2.WriteData("BbbShared"+parsed.to_json)
  	end
  	fromSharedMem = @sharedBbbGpio2.GetData()

	# End of 'def initialize'
  end 
  
    def getBits(dataParam)
        # puts "dataParam=#{dataParam} dataParam.class=#{dataParam.class} #{__LINE__}-#{__FILE__}"
        bits = dataParam.to_s(2)
        while bits.length < 8
            bits = "0"+bits
        end
        return bits
    end

    def forTesting_getGpio2State
        fromSharedMem = @sharedBbbGpio2.GetData()
        if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
            # The shared memory has some legit data in it.
            parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
        else
            parsed = Hash.new
        end
        return parsed
    end
  
  def setBitOff(addrParam, dataParam)
        #
        # This value turns off the state of a bit listed in 'dataParam' on a given register address 'addrParam'
        #
      inBits = getBits(dataParam)
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : bit to turn off."
      hold = ~dataParam
=begin      
      inBits = getBits(hold)
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : bits after the tilde."
      inBits = getBits(@regValues[addrParam])
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : value before of what to turn off."
      @regValues[addrParam] = 
      inBits = getBits(@regValues[addrParam])
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : value after turning off."
=end      
      setGPIO2(addrParam, @regValues[addrParam]&hold)
  end
  
    def setBitOn(addrParam, dataParam)
        #
        # This value turns on the state of a bit listed in 'dataParam' on a given register address 'addrParam'
        #
      inBits = getBits(dataParam)
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : bit to turn on."
=begin      
      inBits = getBits(@regValues[addrParam])
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : value of what to turn on."
      @regValues[addrParam] = 
      inBits = getBits(@regValues[addrParam])
      puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : value after turning on."
=end      
      setGPIO2(addrParam, @regValues[addrParam]|dataParam)
  end
  
    def setGPIO2(addrParam, dataParam)
        #
        # This function sets a value 'dataParam' on a given register address 'addrParam',
        #        
        
        fromSharedMem = @sharedBbbGpio2.GetData()
        if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
            # The shared memory has some legit data in it.
            parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
        else
            parsed = Hash.new
        end
        
        parsed[addrParam.to_s] = dataParam
        @sharedBbbGpio2.WriteData("BbbShared"+parsed.to_json)
        
        if @regValues[addrParam].nil? == false
            inBits = getBits(@regValues[addrParam])
            puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : Current value."
        end
=begin        
        inBits = getBits(dataParam)
        puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : Setting to."
=end        
        @regValues[addrParam] = dataParam
        inBits = getBits(@regValues[addrParam])
        puts "addr=0x#{addrParam.to_s(16)} - #{inBits} : New value."
        
        #
        # Send data to real time register data viewer
        #
        hostname = 'localhost'
        port = 2000
        begin
            s = TCPSocket.open(hostname, port)
            
            s.puts parsed.to_json
            s.close               # Close the socket when done
            rescue Exception => e  
                # puts e.message  
                # puts e.backtrace.inspect  
        end        

        sendToPort2(addrParam,dataParam)
        # End of 'def setGPIO2(addrParam, dataParam)'
    end
  
    def getGPIO2(addrParam)
        #
        # This function returns the value of a given address 'addrParam' of a register.
        #

        if @emulatorEnabled == true
            fromSharedMem = @sharedBbbGpio2.GetData()
            if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
                # The shared memory has some legit data in it.
                parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
            else
                parsed = Hash.new
            end
            
            return parsed[addrParam.to_s].to_i
        else    
            return getFromPort2(addrParam)
        end
    end
    
  def getForInitGetImagesOf16Addrs
      #
      # This function must get called first in order the get the values of the registers.
      #
      puts "within - getForInitGetImagesOf16Addrs #{__LINE__}-#{__FILE__}"
      @regValues[SLOT_ADDR_x0] = getGPIO2(SLOT_ADDR_x0)
      @regValues[LED_STAT_x1] = getGPIO2(LED_STAT_x1)
      @regValues[EXT_INPUTS_x2] = getGPIO2(EXT_INPUTS_x2)
      @regValues[PS_ENABLE_x3] = getGPIO2(PS_ENABLE_x3)
      @regValues[EXT_SLOT_CTRL_x4] = getGPIO2(EXT_SLOT_CTRL_x4)
      @regValues[SLOT_FAN_PWM_x5] = getGPIO2(SLOT_FAN_PWM_x5)
      @regValues[ETS_ALM1_x6] = getGPIO2(ETS_ALM1_x6)
      @regValues[ETS_ALM2_x7] = getGPIO2(ETS_ALM2_x7)
      @regValues[ETS_ALM3_x8] = getGPIO2(ETS_ALM3_x8)
      @regValues[ETS_ENA1_x9] = getGPIO2(ETS_ENA1_x9)
      @regValues[ETS_ENA2_xA] = getGPIO2(ETS_ENA2_xA)
      @regValues[ETS_ENA3_xB] = getGPIO2(ETS_ENA3_xB)
      @regValues[ETS_RX_SEL_xC] = getGPIO2(ETS_RX_SEL_xC)
      @regValues[ANA_MEAS4_SEL_xD] = getGPIO2(ANA_MEAS4_SEL_xD)
      
      puts "@regValues[SLOT_ADDR_x0] = 0x#{@regValues[SLOT_ADDR_x0].to_s(16)}"
      puts "@regValues[LED_STAT_x1] = 0x#{@regValues[LED_STAT_x1].to_s(16)}"
      puts "@regValues[EXT_INPUTS_x2] = 0x#{@regValues[EXT_INPUTS_x2].to_s(16)}"
      puts "@regValues[PS_ENABLE_x3] = 0x#{@regValues[PS_ENABLE_x3].to_s(16)}"
      puts "@regValues[EXT_SLOT_CTRL_x4] = 0x#{@regValues[EXT_SLOT_CTRL_x4].to_s(16)}"
      puts "@regValues[SLOT_FAN_PWM_x5] = 0x#{@regValues[SLOT_FAN_PWM_x5].to_s(16)}"
      puts "@regValues[ETS_ALM1_x6] = 0x#{@regValues[ETS_ALM1_x6].to_s(16)}"
      puts "@regValues[ETS_ALM2_x7] = 0x#{@regValues[ETS_ALM2_x7].to_s(16)}"
      puts "@regValues[ETS_ALM3_x8] = 0x#{@regValues[ETS_ALM3_x8].to_s(16)}"
      puts "@regValues[ETS_ENA1_x9] = 0x#{@regValues[ETS_ENA1_x9].to_s(16)}"
      puts "@regValues[ETS_ENA2_xA] = 0x#{@regValues[ETS_ENA2_xA].to_s(16)}"
      puts "@regValues[ETS_ENA3_xB] = 0x#{@regValues[ETS_ENA3_xB].to_s(16)}"
      puts "@regValues[ETS_RX_SEL_xC] = 0x#{@regValues[ETS_RX_SEL_xC].to_s(16)}"
      puts "@regValues[ANA_MEAS4_SEL_xD] = 0x#{@regValues[ANA_MEAS4_SEL_xD].to_s(16)}"
      # puts "<at a pause>"
      # gets
  end
  
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
    
    def checkBits
        puts "       - Paused for checking register value.  Press enter to continue."
        gets # for pause so you could see the emulator value update.
    end

    def testOnOffBits
        getForInitGetImagesOf16Addrs
=begin        
        setBitOn(SLOT_ADDR_x0,W0_Reset)
        gets # for pause so you could see the emulator value update.
        setBitOff(SLOT_ADDR_x0,W0_Reset)
        gets # for pause so you could see the emulator value update.
        inBits = getGPIO2(EXT_INPUTS_x2)
        inBits = getBits(inBits)
        puts "addr=0x#{EXT_INPUTS_x2.to_s(16)} - #{inBits} : Get value of EXT_INPUTS_x2."
        checkBits
        
        puts "\nTesting slotAddrReset function.  Make sure register SLOT_ADDR_x0 bit W0_Reset is on."
        slotAddrReset
        checkBits

        puts "\nTesting slotAddrGet function.  Make sure the function returns the values given on register "
        print " SLOT_ADDR_x0."
        puts "slotAddrGet = '0x#{slotAddrGet.to_s(16)}'"
        checkBits

        onParam = 1
        puts "\nTesting ledStatEnableSet(onParam) function."
        puts "This function sets the LEDEN bit.  If ON, it will set the state of the LEDs on register LED_STAT_x1"
        puts "ledStatEnableSet(#{onParam})"
        ledStatEnableSet(onParam)        
        checkBits

        ledState = 3
        puts "\nTesting ledStatSet(ledState) function."
        puts "This function sets the state of the LEDs, and only applies after the LEDEN bit has been enabled."
        puts "Returns true if the GPIO was set."
        puts "        false if the W1_LEDEN hasn't been set and GPIO setting was not called or if the ledState "
        puts "        values don't fit the expected bit parameters."
        puts "ledStatSet(#{ledState}) = #{ledStatSet(ledState)}"
        checkBits

        puts "\nTesting extInputsGet() function."
        puts "Function definition:"
        puts "Read External Inputs.  Inputs are latched to guarantee the bit status are high.  EXT_CLEAR_LATCH bit"
        puts "must be set after every read to clear the register."
        puts "extInputsGet()=#{extInputsGet().to_s(16)}"
        checkBits
        

        bitsParam = 3
        puts "\nTesting PsEnable(bitsParam) function."
        puts "Function definition:"
        puts "Write bit-wise to enable or sequence up power/down power to the slot"
        puts "  Expected parameters in bits, ie: W3_P12V+W3_PS8 to turn on W3_P12V and W3_PS8"
        puts "  Below are the list of possible bits."
        puts "      W3_P12V"
        puts "      W3_N5V"
        puts "      W3_P5V"
        puts "      W3_PS6"
        puts "      W3_PS8"
        puts "      W3_PS9"
        puts "      W3_PS10"
        puts "psEnable(#{bitsParam})"
        psEnable(bitsParam)
        checkBits

        bitsParam = 3
        puts "\nslotCntlExtSet(bitsParam) function."
        puts "Function definition:"
        puts " Sets the user panel interface indicating the status, or enabling items."
        puts "   Expected parameters in bits."
        puts "       X4_POWER"
        puts "       _X4_FAN1 - *" 
        puts "       _X4_FAN2 - *"
        print "           * - it was noted that these don't need to be turned on because their state is based on "
        puts "the values"
        print "               provided in SLOT_FAN_PWM_x5 register.  If SLOT_FAN_PWM_x5 returns a value greater "
        puts "than 0"
        puts "               bit X4_FAN1 or _X4_FAN2 are high."
        puts "       X4_BUZR"
        puts "       X4_LEDRED"
        puts "       X4_LEDYEL"
        puts "       X4_LEDGRN"
        puts ""
        puts "   Returns true bits are called through, else false"
        puts "slotCntlExtSet(#{bitsParam})=#{slotCntlExtSet(bitsParam)}"
        checkBits
=end        

        bitsParam = 116
        puts "\nslotFanPulseWidthModulator(#{bitsParam}) function."
        puts "Function definition:"
        puts ""
        puts " Write to the fan speed control register 0x0=off, 0xff (255) = full speed."
        puts ""
        puts ""
        puts " If the bitsParam>0, the fan bit on register EXT_SLOT_CTRL_x4 are set to on, else off."
        puts ""
        puts "   Returns true bits are called through, else false"
        slotFanPulseWidthModulator(bitsParam)
        checkBits
=begin
        puts "\netsAlarm1Get function."
        puts "Function definition:"
        puts ""
        print " Reads temp controller alarm status bits for register ETS_ALM1_x6.  Alarm indication of an immediate"
        puts " issue"
        puts " with a thermal controller."
        puts "etsAlarm1Get=#{etsAlarm1Get.to_s(16)}"
        checkBits
        
        puts "\netsAlarm2Get function."
        puts "Function definition:"
        puts ""
        print " Reads temp controller alarm status bits for register ETS_ALM2_x7.  Alarm indication of an immediate "
        puts "issue"
        puts " with a thermal controller."
        puts "etsAlarm2Get=#{etsAlarm2Get.to_s(16)}"
        checkBits
        
        puts "\netsAlarm3Get function."
        puts "Function definition:"
        puts ""
        print " Reads temp controller alarm status bits for register ETS_ALM3_x8.  Alarm indication of an immediate"
        puts " issue"
        puts " with a thermal controller."
        puts "etsAlarm3Get=#{etsAlarm3Get.to_s(16)}"
        checkBits
        
        byteParam = 4
        puts "\netsEna1Set function."
        puts "Function definition:"
        puts ""
        puts " Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA1_x9."
        puts ""
        puts "etsEna1Set(#{byteParam.to_s(16)})"
        etsEna1Set(byteParam)
        checkBits
        
        puts "\netsEna2Set function."
        puts "Function definition:"
        puts ""
        puts " Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA2_xA."
        puts ""
        puts "esEna2Set(#{byteParam.to_s(16)})"
        etsEna2Set(byteParam)
        checkBits
        
        puts "\etsEna3Set function."
        puts "Function definition:"
        puts ""
        puts " Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA3_xB."
        puts ""
        puts "etsEna3Set(#{byteParam.to_s(16)})"
        etsEna3Set(byteParam)
        checkBits
=end        
    end
    
    def slotAddrReset
        #
        # This function does a complete reset on the board.  Only on power up and reset required.
        #
        setBitOn(SLOT_ADDR_x0,W0_Reset)
    end
    
    def slotAddrGet
        #
        # This function gets the last byte of the IP address of the slot system.
        #
        return getGPIO2(SLOT_ADDR_x0)
    end
    
    def ledStatSet(ledState)
        #
        # This function sets the state of the LEDs, and only applies after the LEDEN bit has been enabled.
        # Returns true if the GPIO was set.
        #         false if the W1_LEDEN hasn't been set and GPIO setting was not called or if the ledState values
        #         don't fit the expected bit parameters.
        #
        if @regValues[LED_STAT_x1]&W1_LEDEN == W1_LEDEN && (~(X1_LED3|X1_LED2|X1_LED1|X1_LED0)&ledState == 0) == true
            setGPIO2(LED_STAT_x1, ledState)
            return true
        else
            puts "failed on LedStatSet(0x#{ledState.to_s(16)}) #{__LINE__}-#{__FILE__}"
            puts "    - @regValues[LED_STAT_x1]&W1_LEDEN='#{@regValues[LED_STAT_x1]&W1_LEDEN}'"
            print "    - ~(X1_LED3|X1_LED2|X1_LED1|X1_LED0)&ledState="
            print "'#{getBits(~(X1_LED3|X1_LED2|X1_LED1|X1_LED0))}&#{getBits(ledState)}'="
            print "#{~(X1_LED3|X1_LED2|X1_LED1|X1_LED0)&ledState}"
            puts
            return false
        end
    end

    def ledStatEnableSet(onParam)
        #
        # This function sets the LEDEN bit.  If ON, it will set the state of the LEDs on register LED_STAT_x1
        #
        if onParam == 1
            setBitOn(LED_STAT_x1,W1_LEDEN)
        else
            setBitOff(LED_STAT_x1,W1_LEDEN)
        end
    end
    
    def extInputsGet()
        #
        # Read External Inputs.  Inputs are latched to guarantee the bit status are high.  W2_CLEAR bit
        # on EXT_INPUTS_x2 must be set after every read to clear the register.
        #
        
        #
        # Gets the states of the External Inputs
        #
        externalInputs = getGPIO2(EXT_INPUTS_x2)
        
        #
        # Clears the latch
        #
        setBitOn(EXT_INPUTS_x2,W2_CLEAR)
        
        return externalInputs
    end
    
    def psEnable (bitsParam)
        #
        # Write bit-wise to enable or sequence up power/down power to the slot
        #   Expected parameters in bits, ie: W3_P12V+W3_PS8 to turn on W3_P12V and W3_PS8
        #   Below are the list of possible bits.
        #       W3_P12V
        #       W3_N5V
        #       W3_P5V
        #       W3_PS6
        #       W3_PS8
        #       W3_PS9
        #       W3_PS10
        #
        setGPIO2(PS_ENABLE_x3, bitsParam)
    end
    
    def slotCntlExtSet(bitsParam)
        #
        # Sets the user panel interface indicating the status, or enabling items.
        #   Expected parameters in bits.
        #       X4_POWER
        #       _X4_FAN1 - * 
        #       _X4_FAN2 - *
        #           * - it was noted that these don't need to be turned on because their state is based on the values
        #               provided in SLOT_FAN_PWM_x5 register.  If SLOT_FAN_PWM_x5 returns a value greater than 0
        #               bit X4_FAN1 or _X4_FAN2 are high.
        #       X4_BUZR
        #       X4_LEDRED
        #       X4_LEDYEL
        #       X4_LEDGRN
        #
        #   Returns true bits are called through, else false
        #
        
        #
        # Make sure valid bit parameters are sent.
        #
        if ~(X4_POWER+X4_BUZR+X4_LEDRED+X4_LEDYEL+X4_LEDGRN)&bitsParam == 0
            setGPIO2(EXT_SLOT_CTRL_x4, bitsParam)
            return true
        else
            puts "failed on SlotCntlExtSet(#{bitsParam.to_s(16)}) #{__LINE__}-#{__FILE__}"
            print "    ~(X4_POWER+X4_BUZR+X4_LEDRED+X4_LEDYEL+X4_LEDGRN)&bitsParam = "
            print "    #{getBits(~(X4_POWER+X4_BUZR+X4_LEDRED+X4_LEDYEL+X4_LEDGRN))}&#{getBits(bitsParam)}"
            puts
            return false
        end
    end
    
    def slotFanPulseWidthModulator(bitsParam)
        #
        # Write to the fan speed control register 0x0=off, 0xff (255) = full speed.
        #
        setGPIO2(SLOT_FAN_PWM_x5, bitsParam)
        
        #
        # If the bitsParam>0, the fan bits on register EXT_SLOT_CTRL_x4 are set to on, else off.
        #
=begin        
        if bitsParam>0
            setBitOn(EXT_SLOT_CTRL_x4,X4_FAN1)
            setBitOn(EXT_SLOT_CTRL_x4,X4_FAN2)
        else
            setBitOff(EXT_SLOT_CTRL_x4,X4_FAN1)
            setBitOff(EXT_SLOT_CTRL_x4,X4_FAN2)
        end
=end        
    end

    def etsAlarm1Get
        #
        # Reads temp controller alarm status bits for register ETS_ALM1_x6.  Alarm indication of an immediate issue
        # with a thermal controller.
        #
        return getGPIO2(ETS_ALM1_x6)
    end
    
    def etsAlarm2Get
        #
        # Reads temp controller alarm status bits for register ETS_ALM2_x7.  Alarm indication of an immediate issue
        # with a thermal controller.
        #
        return getGPIO2(ETS_ALM2_x7)
    end
    
    def etsAlarm3Get
        #
        # Reads temp controller alarm status bits for register ETS_ALM3_x8.  Alarm indication of an immediate issue
        # with a thermal controller.
        #
        return getGPIO2(ETS_ALM3_x8)
    end
    
    def etsEna1Set(byteParam)
        #
        # Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA1_x9.
        #
        setGPIO2(ETS_ENA1_x9, byteParam)
    end
    
    def etsEna2Set(byteParam)
        #
        # Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA2_xA.
        #
        setGPIO2(ETS_ENA2_xA, byteParam)
    end
    
    def etsEna3Set(byteParam)
        #
        # Write bitwise to enabled or disable a temperature controller unit on register ETS_ENA3_xB.
        #
        setGPIO2(ETS_ENA3_xB, byteParam)
    end
    
    def etsRxSel(muxParam)
        #
        # muxParam is the mux parameter for selecting which temperature controller to commumicate to.  Limit 1 to 24.
        #
        # Code not implemented.
        # returns the TCU status
        setGPIO2(ETS_RX_SEL_xC, muxParam)
        
        #
        # Now read/write to UART0
        #
    end
    
    def analogMeasureSelect(muxParam)
        #
        # muxParam is the mux parameter for selecting which input is desired to measure on ANA4 port.
        # Limit of muxParam 1 to 48.
        #
        # Code not implemented.
        # returns the analog measurement.
        setGPIO2(ANA_MEAS4_SEL_xD, muxParam)
    end
    
=begin    
    class << self
      extend Forwardable
      def_delegators :instance, *GPIO2.instance_methods(false)
    end    
=end
    # End of 'class GPIO2'
end

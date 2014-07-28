#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'Port2Interface.so'
require 'beaglebone'
require 'singleton'
require 'forwardable'


class GPIO2
    include Beaglebone
    include Port2Interface
    include Singleton
    
    def initialize
        GPIOPin.new(:P8_45, :IN) 
        GPIOPin.new(:P8_46, :IN) 
        GPIOPin.new(:P8_43, :IN) 
        GPIOPin.new(:P8_44, :IN) 
        GPIOPin.new(:P8_41, :IN) 
        GPIOPin.new(:P8_42, :IN) 
        GPIOPin.new(:P8_39, :IN) 
        GPIOPin.new(:P8_40, :IN) 
        initPort2()
        # End of 'def initialize'
    end 
    
    def setGPIO2(addrParam, dataParam)
        sendToPort2(addrParam,dataParam)
        # End of 'def setGPIO2(addrParam, dataParam)'
    end
    
    def getGPIO2(addrParam)
        return getFromPort2(addrParam)
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
        X0_SLOT1            = 0x80
        X0_SLOT0            = 0x40
        X0_SYS5             = 0x20
        X0_SYS4             = 0x10
        X0_SYS3             = 0x08
        X0_SYS2             = 0x04
        X0_SYS1             = 0x02
        X0_SYS0             = 0x01
    LED_STAT_x1         = 0x1
        X1_LEDEN            = 0x80
        X1_LED3             = 0x08
        X1_LED2             = 0x04
        X1_LED1             = 0x02
        X1_LED0             = 0x01
    EXT_INPUTS_x2       = 0x2
        X2_FANT2B           = 0x80
        X2_FANT2A           = 0x40
        X2_FANT1B           = 0x20
        X2_FANT1A           = 0x10
        X2_SENSR2           = 0x08
        X2_SENSR1           = 0x04
        X2_USRSW2           = 0x02
        X2_USRSW1           = 0x01
    PS_ENABLE_x3        = 0x3
        X3_P12V             = 0x40
        X3_N5V              = 0x20
        X3_P5V              = 0x10
        X3_PS6              = 0x08
        X3_PS8              = 0x04
        X3_PS9              = 0x02
        X3_PS10             = 0x01
    EXT_SLOT_CTRL_x4    = 0x4
        X4_POWER            = 0x80
        X4_FAN1             = 0x20
        X4_FAN2             = 0x10
        X4_BUZR             = 0x08
        X4_LEDRED           = 0x04
        X4_LEDYEL           = 0x02
        X4_LEDGRN           = 0x01
    SLOT_FAN_PWM_x5     = 0x5
        X5_PWM7             = 0x80
        X5_PWM6             = 0x40
        X5_PWM5             = 0x20
        X5_PWM4             = 0x10
        X5_PWM3             = 0x08
        X5_PWM2             = 0x04
        X5_PWM1             = 0x02
        X5_PWM0             = 0x01
    ETS_ALM1_x6         = 0x6
        X6_ALM7             = 0x80
        X6_ALM6             = 0x40
        X6_ALM5             = 0x20
        X6_ALM4             = 0x10
        X6_ALM3             = 0x08
        X6_ALM2             = 0x04
        X6_ALM1             = 0x02
        X6_ALM0             = 0x01
    ETS_ALM2_x7         = 0x7
        X7_ALM15            = 0x80
        X7_ALM14            = 0x40
        X7_ALM13            = 0x20
        X7_ALM12            = 0x10
        X7_ALM11            = 0x08
        X7_ALM10            = 0x04
        X7_ALM9             = 0x02
        X7_ALM8             = 0x01
    ETS_ALM3_x8         = 0x8
        X8_ALM23            = 0x80
        X8_ALM22            = 0x40
        X8_ALM21            = 0x20
        X8_ALM20            = 0x10
        X8_ALM19            = 0x08
        X8_ALM18            = 0x04
        X8_ALM17            = 0x02
        X8_ALM16            = 0x01
    ETS_ENA1_x9         = 0x9
        X9_ETS7             = 0x80
        X9_ETS6             = 0x40
        X9_ETS5             = 0x20
        X9_ETS4             = 0x10
        X9_ETS3             = 0x08
        X9_ETS2             = 0x04
        X9_ETS1             = 0x02
        X9_ETS0             = 0x01
    ETS_ENA2_xA         = 0xA
        XA_ETS15            = 0x80
        XA_ETS14            = 0x40
        XA_ETS13            = 0x20
        XA_ETS12            = 0x10
        XA_ETS11            = 0x08
        XA_ETS10            = 0x04
        XA_ETS09            = 0x02
        XA_ETS08            = 0x01
    ETS_ENA3_xB         = 0xB
        XB_ETS23            = 0x80
        XB_ETS22            = 0x40
        XB_ETS21            = 0x20
        XB_ETS20            = 0x10
        XB_ETS19            = 0x08
        XB_ETS18            = 0x04
        XB_ETS17            = 0x02
        XB_ETS16            = 0x01
    ETS_RX_SEL_xC       = 0xC
        XC_RXMUX4           = 0x10
        XC_RXMUX3           = 0x08
        XC_RXMUX2           = 0x04
        XC_RXMUX1           = 0x02
        XC_RXMUX0           = 0x01
    ANA_MEAS4_SEL_xD    = 0xD
        XD_ANAMUX5          = 0x20
        XD_ANAMUX4          = 0x10
        XD_ANAMUX3          = 0x08
        XD_ANAMUX2          = 0x04
        XD_ANAMUX1          = 0x02
        XD_ANAMUX0          = 0x01
    
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
    
    class << self
      extend Forwardable
      def_delegators :instance, *GPIO2.instance_methods(false)
    end    
    # End of 'class GPIO2'
end

require_relative 'DutObj'
require 'singleton'
require 'forwardable'

class ThermalSiteDevices 
    include Singleton
    
    attr_accessor :dBase_
    
    def etsEnaBit(ct)
        if 8<= ct && ct <= 15
            ct -= 8
        elsif 16 <= ct && ct <= 23
            ct -= 16
        end

        if 0<=ct && ct <=7
            case ct
            when 7
                return GPIO2::X9_ETS7
            when 6
                return GPIO2::X9_ETS6
            when 5
                return GPIO2::X9_ETS5
            when 4 
                return GPIO2::X9_ETS4
            when 3
                return GPIO2::X9_ETS3
            when 2
                return GPIO2::X9_ETS2
            when 1
                return GPIO2::X9_ETS1
            when 0
                return GPIO2::X9_ETS0
            end
        end
    end
    
    def setTcuToRunMode(tcusToSkipParam,gPIO2Param)
        # Turn on the control for TCUs that are not disabled.
        SharedLib.bbbLog "Turning on controllers.  #{__LINE__}-#{__FILE__}"
        ct = 0
        while ct<24 do
            if tcusToSkipParam[ct].nil? == true
                bitToUse = etsEnaBit(ct)
                if 0<=ct && ct <=7  
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna1Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    gPIO2Param.etsEna1SetOn(bitToUse)
                elsif 8<=ct && ct <=15
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna2Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    gPIO2Param.etsEna2SetOn(bitToUse)
                elsif 16<=ct && ct <=23
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna3Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    gPIO2Param.etsEna3SetOn(bitToUse)
                end
            end
            ct += 1
        end
    end    
    
    def dBase
        if @dBase_.nil?
            # puts "ThermalSiteDevices.dBase accessor got called" # from #{file} - #{line}"
            @dBase_ = DutObj.new()
        # else
        #     puts "ThermalSiteDevices.dBase accessor got called.  dBase object is not null." # :  #{file} - #{line}"
            # End of 'if @dBase_.nil?'
        end
        @dBase_
    end
    
    def initialize
        # End of 'def initialize'
    end
    
    def setTHCPID(uart1Param,keyParam,tcusToSkip,temParam)
        #puts "setTHCPID '#{keyParam}' = '#{temParam}'"
        dutNum = 0;
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT do
            if  tcusToSkip[dutNum].nil?  
                dBase.setTHCPID(keyParam,uart1Param,temParam)
                dutNum = TOTAL_DUTS_TO_LOOK_AT # break out of the loop since we're doing it only in one call.
            end
            dutNum +=1;
        end            
    end
    
    def pollDevices(uart1,gPIO2,tcusToSkip,tsdParam)
        # puts "A - "+Time.now.inspect+" - ThermalSiteDevices.pollDevices function got called."
        # puts "tcusToSkip='#{tcusToSkip}' TOTAL_DUTS_TO_LOOK_AT='#{TOTAL_DUTS_TO_LOOK_AT}'"
        dutNum = 0;
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT do
            if  tcusToSkip[dutNum].nil?  
                # puts "Polling dutNum='#{dutNum}' #{__LINE__}-#{__FILE__}"
                dBase.poll(dutNum,uart1,gPIO2,tcusToSkip,tsdParam)
            end
            dutNum +=1;
        end            
        # End of 'def PollDevices'
    end
    
    def analyzeData
        # End of 'def analyzeData'  
    end
    
    def logData(parentMemory,tcusToSkip)
        # Did we get the data?
        # puts "   #{Time.now.to_f.inspect} - ThermalSiteDevices.logData function got called A."
        dBase.saveAllData(parentMemory,tcusToSkip,Time.now)
        # puts "   #{Time.now.to_f.inspect} - ThermalSiteDevices.logData function got called B."
        # End of 'def logData'
    end

    class << self
      extend Forwardable
      def_delegators :instance, *ThermalSiteDevices.instance_methods(false)
    end
    
    # End of 'class ThermalSiteDevices'
end
# kill variable logData function
require_relative 'DutObj'
require 'singleton'
require 'forwardable'

class ThermalSiteDevices 
    include Singleton
    
    attr_accessor :dBase_
    
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
    
    def pollDevices(uart1,gPIO2,tcusToSkip)
        puts "A - "+Time.now.inspect+" - ThermalSiteDevices.pollDevices function got called."
        puts "tcusToSkip='#{tcusToSkip}' TOTAL_DUTS_TO_LOOK_AT='#{TOTAL_DUTS_TO_LOOK_AT}'"
        dutNum = 0;
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT do
            if  tcusToSkip[dutNum].nil?  
                puts "B - dutNum='#{dutNum}' #{__LINE__}-#{__FILE__}"
                dBase.poll(dutNum,uart1,gPIO2)
            end
            dutNum +=1;
        end            
        # End of 'def PollDevices'
    end
    
    def analyzeData
        # End of 'def analyzeData'  
    end
    
    def logData(parentMemory)
        # Did we get the data?
        # puts "   #{Time.now.to_f.inspect} - ThermalSiteDevices.logData function got called A."
        dBase.saveAllData(parentMemory,Time.now)
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
require_relative 'DutObj'
require 'singleton'
require 'forwardable'

class ThermalSiteDevices 
    include Singleton
    
    attr_accessor :dBase_
    
    def dBase=(dBaseParam)
        @dBase_ = dBaseParam
    end

    def dBase
        if @dBase_.nil?
            # puts "ThermalSiteDevices.dBase accessor got called" # from #{file} - #{line}"
            @dBase_ = DutObj.new(@totalHoursToLog_Interval_UnitsInHours,self)
        # else
        #     puts "ThermalSiteDevices.dBase accessor got called.  dBase object is not null." # :  #{file} - #{line}"
            # End of 'if @dBase_.nil?'
        end
        @dBase_
    end
    
    def initialize
        # End of 'def initialize'
    end
    
    def pollDevices(uart1)
        # puts Time.now.inspect+" - ThermalSiteDevices.pollDevices function got called."
        dutNum = 0;
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do
            dBase.poll(dutNum,uart1)
            dutNum +=1;
        end            
        # End of 'def PollDevices'
    end
    
    def analyzeData
        # End of 'def analyzeData'  
    end
    
    def logData
        # Did we get the data?
        # puts "   #{Time.now.to_f.inspect} - ThermalSiteDevices.logData function got called A."
        dBase.saveAllData(Time.now)
        # puts "   #{Time.now.to_f.inspect} - ThermalSiteDevices.logData function got called B."
        # End of 'def logData'
    end

    def setTotalHoursToLogData(totalHoursToLog_Interval_UnitsInHoursParam)
        #
        # Expected units: Hours
        #
        @totalHoursToLog_Interval_UnitsInHours = totalHoursToLog_Interval_UnitsInHoursParam
        # End of 'def hoursToLogData'
    end
    
    class << self
      extend Forwardable
      def_delegators :instance, *ThermalSiteDevices.instance_methods(false)
    end
    
    # End of 'class ThermalSiteDevices'
end

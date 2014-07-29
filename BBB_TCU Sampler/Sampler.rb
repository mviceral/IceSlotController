# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'timeout'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'ThermalSiteDevices'
require 'singleton'
require 'forwardable'

TOTAL_DUTS_TO_LOOK_AT  = 24

class TCUSampler
    # Special note regarding file openTtyO1Port_115200.exe, this comes from the folder BBB_openTtyO1Port c code, and 
    # it's compiled as an executable.
    #
    # system("./openTtyO1Port_115200.exe")
    include Singleton
    include Beaglebone

    
    def runTCUSampler
        #
        # Create log interval unit: hours
        #
        createLogInterval_UnitsInHours = 1 
        
        #
        # Do a poll for every pollInterval in seconds
        #
        pollIntervalInSeconds = 10 
        
        executeAllStty = "Yes" # "Yes" if you want to execute all...
        
        baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
    
        # puts 'Check 1 of 7 - cd /lib/firmware'
        system("cd /lib/firmware")
        
        # puts 'Check 2 of 7 - echo BB-UART1 > /sys/devices/bone_capemgr.9/slots'
        system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")
        
        # puts 'Check 4 of 7 - stty -F /dev/ttyO1 raw'
        system("stty -F /dev/ttyO1 raw")
        
        # puts "Check 5 of 7 - stty -F /dev/ttyO1 #{baudrateToUse}"
    	system("stty -F /dev/ttyO1 #{baudrateToUse}")
    	
        # puts "Check 3 of 7 - ./openTtyO1Port_#{baudrateToUse}.exe"
    	# system("../BBB_openTtyO1Port c code/openTtyO1Port_115200.exe")
    	system("./openTtyO1Port_115200.exe")
    	
    	# End of 'if (executeAllStty == "Yes")'
    
        # puts "Check 6 of 7 - uart1 = UARTDevice.new(:UART1, #{baudrateToUse})"
        uart1 = UARTDevice.new(:UART1, baudrateToUse)
        
    
        #puts "Check 7 of 7 - Start polling..."
        #puts "Press the restart button on the ThermalSite unit..."
        puts "Logging 23 dut thermalsites."
    
        #
        # Do an infinite loop for this code.
        #
        ThermalSiteDevices.setTotalHoursToLogData(createLogInterval_UnitsInHours)
        waitTime = Time.now+pollIntervalInSeconds
        # allDuts = AllDuts.new(createLogInterval_UnitsInHours)
        switcher = 0
        while true
            #
            # Gather data...
            #
            # puts "Start polling: #{Time.now.inspect}"
            ThermalSiteDevices.pollDevices(uart1)
            # puts "Done polling: #{Time.now.inspect}"
            ThermalSiteDevices.logData
            # puts "Done logging: #{Time.now.inspect}"
        
            #
            # What if there was a hiccup and waitTime-Time.now becomes negative
            # The code ensures that the process is exactly going to take place at the given interval.  No lag that
            # takes place on processing data.
            #
            if (waitTime-Time.now)<0
                #
                # The code fix for the scenario above.  I can't get it to activate the code below, unless
                # the code was killed...
                #
                puts "#{Time.now.inspect} Warning - time to complete polling took longer than poll interval!!!"
                # exit # - the exit code...
                #
                # waitTime = Time.now+pollInterval
            else
                sleep(waitTime.to_f-Time.now.to_f) 
            end
            waitTime = waitTime+pollIntervalInSeconds
        end

        # End of 'def runTCUSampler'
    end
    
        
    class << self
      extend Forwardable
      def_delegators :instance, *TCUSampler.instance_methods(false)
    end
    
    # End of 'class TCUSampler'
end

TCUSampler.runTCUSampler

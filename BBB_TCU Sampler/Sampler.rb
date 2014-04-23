# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'timeout'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'ThermalSiteDevices'
require_relative "../experiments/BBB_GPIO2 Interface Ruby/GPIO2"
require_relative '../lib/SharedLib'
require 'singleton'
require 'forwardable'

TOTAL_DUTS_TO_LOOK_AT  = 24

class TCUSampler
    TimeOfPcUpload = "TimeOfPcUpload"
    Configuration = "Configuration"
    ForPowerSupply = "ForPowerSupply"
    PollIntervalInSeconds = "PollIntervalInSeconds"   
    HoldingTankFilename = "MachineState_DoNotDeleteNorModify.json"
    TimeOfPcLastCmd ="TimeOfPcLastCmd"
    
    # Special note regarding file openTtyO1Port_115200.exe, this comes from the folder BBB_openTtyO1Port c code, and 
    # it's compiled as an executable.
    #
    # system("./openTtyO1Port_115200.exe")
    include Singleton
    include Beaglebone
    
    def getTimeOfPcUpload()
        return @boardData[TimeOfPcUpload].to_i
    end
    
    def setTimeOfPcUpload(timeInIntegerParam)
        @boardData[TimeOfPcUpload] = timeInIntegerParam
    end
	
	def gPIO2
	    if @gpio2.nil?
	        @gpio2 = GPIO2.new
	    end
	    return @gpio2
	end
	
	def bbbLog(sentMessage)
	    log = "#{Time.new.inspect} : #{sentMessage}"
	    puts "#{log}"
        `echo "#{log}">>/var/lib/cloud9/slot-controller/bbbActivity.log`
    end
    
    def setToMode(modeParam, calledFrom)
        SharedMemory.SetBbbMode(modeParam)
        @boardData[BbbMode] = modeParam
        
        #
        # The mode of the board change, log it and save the save of the machine to holding tank.
        #
        bbbLog("Changed to '#{modeParam}' called from [#{calledFrom}].  Saving state to holding tank.")
        saveBoardStateToHoldingTank()
    end
    
    def pause(msgParam,fromParam)
        puts "#{msgParam}"
        puts "      o #{fromParam}"
    end
    
    def setTimeOfPcLastCmd(timeOfPcLastCmdParam)
        @boardData[TimeOfPcLastCmd] = timeOfPcLastCmdParam
    end
    
    def getTimeOfPcLastCmd()
        if @boardData[TimeOfPcLastCmd].nil?
            @boardData[TimeOfPcLastCmd] = 0
        end
        return @boardData[TimeOfPcLastCmd]
    end
    
    def getConfiguration(forParam,fromParam)
        @boardData[Configuration]
        PP.pp(@boardData[Configuration])
        pause("getConfiguration got called. forParam=#{forParam} called from [#{fromParam}]","#{__LINE__}-#{__FILE__}")
    end


    def saveBoardStateToHoldingTank()
	    # Write configuartion to holding tank case there's a power outage.
	    File.open(HoldingTankFilename, "w") { 
	        |file| file.write(@boardData.to_json) 
        }
    end

    def getPollIntervalInSeconds()
        return @boardData[PollIntervalInSeconds]
    end
    
    def setPollIntervalInSeconds(timeInSecParam)
        @boardData[PollIntervalInSeconds] = timeInSecParam
    end
    
    def runTCUSampler
        #
        # Create log interval unit: hours
        #
        createLogInterval_UnitsInHours = 1 
        
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
        
        #
        # Do an infinite loop for this code.
        #
        ThermalSiteDevices.setTotalHoursToLogData(createLogInterval_UnitsInHours)
        switcher = 0

        @boardData = Hash.new
        setTimeOfPcUpload(0)
        setPollIntervalInSeconds(10)
        waitTime = Time.now+getPollIntervalInSeconds()
        #
        # Determine the state of the slot
        #
        gPIO2.getForInitGetImagesOf16Addrs()
        bbbLog("Starting Sampler Code.")
        if gPIO2.getGPIO2(PS_ENABLE_x3)>0
            #
            # Some of the power supplies are on. The system probably had a power outage.
            # Set the board to run mode
            bbbLog("PS_ENABLE_x3=0x#{gPIO2.getGPIO2(PS_ENABLE_x3).to_s(16)} > 0 - meaning some PS are ON.")
            bbbLog("Set board to run mode. #{__LINE__}-#{__FILE__}")
            SharedMemory.SetBbbMode(SharedLib::InRunMode,"#{__LINE__}-#{__FILE__}")
            
            #
            # Get the board configuration
            #
            bbbLog("Get board configuration from holding tank. #{__LINE__}-#{__FILE__}")
            begin
    			fileRead = ""
    			File.open(HoldingTankFilename, "r") do |f|
    				f.each_line do |line|
    					fileRead += line
    				end
    			end
    			@boardData = JSON.parse(fileRead)
    			rescue 
    				# File does not exists, so just continue with a blank slate.
    				bbbLog("There's no data in the holding tank.  Fresh machine starting up. #{__LINE__}-#{__FILE__}")
		    end
		end
        
        while true
			case SharedMemory.GetBbbMode()
			when SharedMemory::InRunMode
                #
                # Gather data...
                #
                bbbLog("'#{SharedMemory::InRunMode}' - poll devices and log data. #{__LINE__}-#{__FILE__}")
                bbbLog("'   TCU not present.  Skipping pollDevices function. #{__LINE__}-#{__FILE__}")
                # ThermalSiteDevices.pollDevices(uart1)
                ThermalSiteDevices.logData
                
                #
                # Check any cmds from PC
                #
        		if getTimeOfPcLastCmd() <= SharedMemory.GetTimeOfPcLastCmd()
        		    setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
        		    case SharedMemory.GetBbbMode()
        		    when SharedLib::RunFromPc
            		    bbbLog("FATAL ERROR inconsistent - From BBB::InRunMode setting to BBB::InRunMode #{__LINE__}-#{__FILE__}")
            		    `echo "#{Time.new.inspect} : FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
        		    when SharedLib::StopFromPc
        		        setToMode(SharedMemory::SequenceDown, "#{__LINE__}-#{__FILE__}")
        		        setToMode(SharedLib::InIdleMode, "#{__LINE__}-#{__FILE__}")
            		end
        		end
			when SharedLib::InIdleMode
				# Update the configuration setup for the process
        		if (SharedMemory.GetTimeOfPcUpload().nil == false &&
        		    @boardData[TimeOfPcUpload].to_i <= SharedMemory.GetTimeOfPcUpload() )
        		    
        		    @boardData[TimeOfPcUpload] = SharedMemory.GetTimeOfPcUpload()
        		    @boardData[Configuration] = SharedMemory.GetConfiguration()
        		    
        		    saveBoardStateToHoldingTank()

        		    # End of 'if timeOfPcUpload <= SharedMemory.GetTimeOfPcUpload()'
        		end
        		
        		if getTimeOfPcLastCmd() <= SharedMemory.GetTimeOfPcLastCmd()
        		    setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
        		    case SharedMemory.GetPcCmd()
        		    when SharedLib::RunFromPc
            		    setToMode(SharedMemory::SequenceUp)
            		    #
            		    # The goal in this code block is to sequence up the power supplies.
            		    #
            		    getConfiguration(ForPowerSupply,"#{__LINE__}-#{__FILE__}")
            		    
            		    #
            		    # Once all the power supplies are all sequenced up, set the system to run mode.
            		    #
            		    setToMode(SharedMemory::InRunMode)
        		    
        		    when SharedLib::StopFromPc
            		    bbbModeAndTime("FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}")
            		    `echo "#{Time.new.inspect} : FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                    when SharedLib::PcCmdNotSet
                        #
                        # We're in idle mode, increase interval of monitoring of any commands coming from the Pc
                        #
                        pollIntervalInSeconds = 1
            		else
            		    SharedMemory.SetPcCmd(SharedLib::PcCmdNotSet)
            		    bbbModeAndTime("Staying in Idle Mode - unknown PC Command '#{SharedMemory.GetPctCmd()}'")
            		    `echo "#{Time.new.inspect} : mode='#{SharedMemory.GetMode()}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
            		end
        		end
				puts ""
            else
                
			    SharedMemory.SetBbbMode(SharedLib::InIdleMode,"#{__LINE__}-#{__FILE__}")
                `echo "#{Time.new.inspect} : mode='#{SharedMemory.GetBbbMode()}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
            end						
            
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
            waitTime += getPollIntervalInSeconds()
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

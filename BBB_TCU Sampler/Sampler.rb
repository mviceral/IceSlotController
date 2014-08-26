# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'timeout'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'ThermalSiteDevices'
require_relative "../experiments/BBB_GPIO2 Interface Ruby/GPIO2"
require_relative '../lib/SharedLib'
require 'singleton'
require 'forwardable'

include Beaglebone

TOTAL_DUTS_TO_LOOK_AT  = 24

class TCUSampler
    
    class PsSeqItem
        
        EthernetOrSlotPcb = "EthernetOrSlotPcb"
        EthernetOrSlotPcb_Ethernent = "Ethernent"
        EthernetOrSlotPcb_SlotPcb = "Slot PCB"
        SeqUp = "SeqUp"
        SUDlyms = "SUDlyms"
        SeqDown = "SeqDown"
        SDDlyms = "SDDlyms"
        
        SPS6 = "SPS6"
        SPS8 = "SPS8"
        SPS9 = "SPS9"
        SPS10 = "SPS10"

        
        def keyName
            return @keyName
        end
        
        def seqOrder
            return @seqOrder
        end
        
        def initialize keyHolderParam, seqOrderParam
            @keyName = keyHolderParam
            @seqOrder = seqOrderParam
        end
    end
    
    FIXNUM_MAX = (2**(0.size * 8 -2) -1)
    
    TimeOfPcUpload = "TimeOfPcUpload"
    Configuration = "Configuration"
    ForPowerSupply = "ForPowerSupply"
    PollIntervalInSeconds = "PollIntervalInSeconds"   
    HoldingTankFilename = "MachineState_DoNotDeleteNorModify.json"
    TimeOfPcLastCmd ="TimeOfPcLastCmd"
    BbbMode = "BbbMode"
    SeqDownPsArr = "SeqDownPsArr"
    SeqUpPsArr = "SeqUpPsArr"
            
    
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
        SharedMemory.SetBbbMode(modeParam,"#{__LINE__}-#{__FILE__}")
        @boardData[BbbMode] = modeParam
        
        #
        # The mode of the board change, log it and save the save of the machine to holding tank.
        #
        bbbLog("Changed to '#{modeParam}' called from [#{calledFrom}].  Saving state to holding tank.")
        saveBoardStateToHoldingTank()
    end
    
    def pause(msgParam,fromParam)
        puts "#{msgParam}"
        puts "      o Paused at #{fromParam}"
        gets
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
    
    def getConfiguration()
        @boardData[Configuration]
    end

    def psSeqDown()
        doPsSeqPower(false)
    end
    
    def psSeqUp()
        doPsSeqPower(true)
    end
    
    def doPsSeqPower(powerUpParam)
        if @stepToWorkOn.nil?
            #
            # Setup the @stepToWorkOn
            #
            setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
    	    stepNumber = 0
    	    puts "getConfiguration().nil? = '#{getConfiguration().nil?}'"
    	    puts "getConfiguration()[\"Steps\"].nil? = #{getConfiguration()["Steps"].nil?}"
    	    while stepNumber<getConfiguration()["Steps"].length && @stepToWorkOn.nil?
    	        if @stepToWorkOn.nil?
                    getConfiguration()[SharedMemory::Steps].each do |key, array|
    		            if @stepToWorkOn.nil?
                            getConfiguration()[SharedMemory::Steps][key].each do |key2, array2|
                                if key2 == SharedMemory::StepNum && 
                                    getConfiguration()[SharedMemory::Steps][key][key2].to_i == (stepNumber+1) &&
                                    getConfiguration()[SharedMemory::Steps][key][SharedMemory::TotalTimeLeft].to_i > 0
                                    @stepToWorkOn = getConfiguration()[SharedMemory::Steps][key]
                                end
                            end
    		            end
                    end            		    
    	        end
    	        stepNumber += 1
    	    end
        end
	    
	    if @stepToWorkOn.nil? 
	        # All steps are done their run process.  Terminate the code.
	        return true
	    end
        
        if powerUpParam
            sortedUp = getSeqUpPsArr()
            textDisp = "'UP'"
        else
            sortedUp = getSeqDownPsArr()
            textDisp = "'DOWN'"
        end
        
        sortedUp.each do |psItem|
            puts "psItem.keyName=#{psItem.keyName}, psItem.seqOrder=#{psItem.seqOrder}"
            if psItem.seqOrder != 0
                # puts "Going to turn on this PS item '#{psItem.keyName}' #{@stepToWorkOn["PsConfig"][psItem.keyName]}"
                if @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_Ethernent
                    print "Sequencing #{textDisp} '#{psItem.keyName}' through 'ETHERNET' for "
                elsif @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_SlotPcb
                    print "Sequencing #{textDisp} '#{psItem.keyName}' through 'Slot PCB' for "
                    case psItem.keyName
                    when PsSeqItem::SPS6
                        if powerUpParam
                            gPIO2.setBitOn((GPIO2::PS_ENABLE_x3).to_i,(GPIO2::W3_PS6).to_i)
                        else
                            gPIO2.setBitOff((GPIO2::PS_ENABLE_x3).to_i,(GPIO2::W3_PS6).to_i)
                        end
                    when PsSeqItem::SPS8
                        if powerUpParam
                            gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS8)
                        else
                            gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS8)
                        end
                    when PsSeqItem::SPS9
                        if powerUpParam
                            gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS9)
                        else
                            gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS9)
                        end
                    when PsSeqItem::SPS10
                        if powerUpParam
                            gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS10)
                        else
                            gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS10)
                        end
                    else
                        `echo "#{Time.new.inspect} : psItem.keyName='#{psItem.keyName}' not recognized.  #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                    end
                    if powerUpParam
                        puts "'#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SUDlyms]}' ms."
                        sleep((@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SUDlyms].to_i)/1000)
                    else
                        puts "'#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SDDlyms]}' ms."
                        sleep((@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SDDlyms].to_i)/1000)
                    end
                    sleep(1)
                else
                    `echo "#{Time.new.inspect} : @stepToWorkOn[\"PsConfig\"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb]='#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb]}' not recognized.  #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                end
            end
        end
    end

    def saveBoardStateToHoldingTank()
	    # Write configuartion to holding tank case there's a power outage.
	    File.open(HoldingTankFilename, "w") { 
	        |file| file.write(@boardData.to_json) 
        }
    end

    def getPollIntervalInSeconds()
        if @boardData[PollIntervalInSeconds].nil?
            @boardData[PollIntervalInSeconds] = 1
        end
        return @boardData[PollIntervalInSeconds]
    end
    
    def setPollIntervalInSeconds(timeInSecParam)
        @boardData[PollIntervalInSeconds] = timeInSecParam
    end
    
    def getSeqDownPsArr()
        if @boardData[SeqDownPsArr].nil?
            @boardData[SeqDownPsArr] = getSeqPs(false)
        end
        return @boardData[SeqDownPsArr]
    end
    
    def getSeqUpPsArr()
        if @boardData[SeqUpPsArr].nil?
            @boardData[SeqUpPsArr] = getSeqPs(true)
        end
        return @boardData[SeqUpPsArr]
    end
    
    def getSeqPs(dirUpParam)
	    # Get all the objects that has SeqUp - then sort the objects
	    objWithSeq = Hash.new
	    if @stepToWorkOn.nil?
	        puts "@stepToWorkOn is nil."
        else
	        puts "@stepToWorkOn is NOT nil."
	    end
	    
	    @stepToWorkOn["PsConfig"].each do |key, array|
            # puts "#{key}-----"
	        @stepToWorkOn["PsConfig"][key].each do |key2, array|
	            if key2 == "SeqUp"
	                objWithSeq[key] = @stepToWorkOn["PsConfig"][key]
	            end
	            # puts "  #{key2}-----"
	        end
        end
        
	    if dirUpParam
            largestSeqNum = 0
        else
            largestSeqNum = FIXNUM_MAX
        end
        
        largestSeqNum = 0
        puts "Checking isolated objects with sequences as sub parts."
	    objWithSeq.each do |key, array|
            # puts "#{key}-----"
	        objWithSeq[key].each do |key2, array2|
	            # puts "   #{key2}-----"
	            # puts "      #{array2}"
	            if dirUpParam
    	            if key2 == "SeqUp"  && largestSeqNum < array2.to_i
    	                largestSeqNum = array2.to_i
    	            end
	            else
    	            if key2 == "SeqDown"  && largestSeqNum < array2.to_i
    	                largestSeqNum = array2.to_i
    	            end
	            end
	        end
        end

        # Sort the order of the sequence.
        sortedUp = Array.new
        largeHolder = largestSeqNum
        while objWithSeq.length>0
            keyHolder = nil
            arrHolder = nil
		    objWithSeq.each do |key, array|
		        objWithSeq[key].each do |key2, array2|
		            # puts "   #{key2}-----"
		            # puts "      #{array2}"
		            if dirUpParam
    		            if key2 == "SeqUp" && largeHolder>=array2.to_i
                            # puts "          #{key2} array2.to_i=#{array2.to_i}"
                            # pause "          paused","#{__LINE__}-#{__FILE__}"
    		                largeHolder = array2.to_i
    		                keyHolder = key
    		                arrHolder = array2
    		            end
		            else
    		            if key2 == "SeqDown" && largeHolder>=array2.to_i
                            # puts "          #{key2} array2.to_i=#{array2.to_i}"
                            # pause "          paused","#{__LINE__}-#{__FILE__}"
    		                largeHolder = array2.to_i
    		                keyHolder = key
    		                arrHolder = array2
    		            end
		            end
		        end
            end

	        # We got the smallest sequp at this point
	        if keyHolder.nil? == false
		        sortedUp.push(PsSeqItem.new(keyHolder, arrHolder.to_i))
                # pause("Isolated seqUp object for sortedUp = #{sortedUp}", "#{__LINE__}-#{__FILE__}")
		        objWithSeq.delete(keyHolder)
		        largeHolder = largestSeqNum
	        end
        end
        
        return sortedUp
    end
    
    def runTCUSampler
        #
        # Create log interval unit: hours
        #
        SharedMemory.Initialize()
        
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
        @stepToWorkOn = nil
        @boardData = Hash.new
        setTimeOfPcUpload(0)
        #
        # Determine the state of the slot
        #
        gPIO2.getForInitGetImagesOf16Addrs()
        bbbLog("Starting Sampler Code.")
        if gPIO2.getGPIO2(GPIO2::PS_ENABLE_x3)>0
            #
            # Some of the power supplies are on. The system probably had a power outage.
            # Set the board to run mode
            bbbLog("PS_ENABLE_x3=0x#{gPIO2.getGPIO2(GPIO2::PS_ENABLE_x3).to_s(16)} > 0 - meaning some PS are ON.")
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
    				setToMode(SharedLib::InIdleMode, "#{__LINE__}-#{__FILE__}")
		    end
		end
        waitTime = Time.now+getPollIntervalInSeconds()
		
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
        		if getTimeOfPcLastCmd() < SharedMemory.GetTimeOfPcLastCmd()
        		    setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
        		    case SharedMemory.GetPcCmd()
        		    when SharedLib::RunFromPc
            		    bbbLog("FATAL ERROR inconsistent - From BBB::InRunMode setting to BBB::InRunMode #{__LINE__}-#{__FILE__}")
            		    `echo "#{Time.new.inspect} : FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
        		    when SharedLib::StopFromPc
        		        puts "within sampler code - PC says STOP #{__LINE__}-#{__FILE__}"
        		        setToMode(SharedMemory::SequenceDown, "#{__LINE__}-#{__FILE__}")
        		        psSeqDown()
        		        setToMode(SharedLib::InIdleMode, "#{__LINE__}-#{__FILE__}")
        		        setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
        		        setPollIntervalInSeconds(1)
            		end
        		end
			when SharedLib::InIdleMode
				# Update the configuration setup for the process
    		    puts "InIdleMode - SharedMemory.GetTimeOfPcUpload()=#{SharedMemory.GetTimeOfPcUpload()}"
        		if (SharedMemory.GetTimeOfPcUpload().nil? == false &&
        		    @boardData[TimeOfPcUpload].to_i < SharedMemory.GetTimeOfPcUpload() )
        		    @boardData[TimeOfPcUpload] = SharedMemory.GetTimeOfPcUpload()
        		    @boardData[Configuration] = SharedMemory.GetConfiguration()
        		    saveBoardStateToHoldingTank()
        		    SharedMemory.SetConfiguration("","#{__LINE__}-#{__FILE__}") # Empty out the shared memory now 
        		        # that we got the configuration transferred into BBB.
        		    # End of 'if timeOfPcUpload <= SharedMemory.GetTimeOfPcUpload()'
        		end
        		
        		if getTimeOfPcLastCmd() < SharedMemory.GetTimeOfPcLastCmd()
        		    puts "New command from PC - '#{SharedMemory.GetPcCmd()}' "
        		    setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
        		    case SharedMemory.GetPcCmd()
        		    when SharedLib::RunFromPc
        		        setTimeOfPcLastCmd(SharedMemory.GetTimeOfPcLastCmd())
            		    setToMode(SharedMemory::SequenceUp,"#{__LINE__}-#{__FILE__}")

            		    #
            		    # The goal in this code block is to sequence up the power supplies on the step that the
            		    # board is active on.
            		    #
            		    #PP.pp(@stepToWorkOn)
            		    psSeqUp()
                        # pause("Above are the listed PS sequence up order.","#{__LINE__}-#{__FILE__}")
            		    #
            		    # Once all the power supplies are all sequenced up, set the system to run mode.
            		    #
            		    setToMode(SharedMemory::InRunMode,"#{__LINE__}-#{__FILE__}")
            		    setPollIntervalInSeconds(10)
            		    saveBoardStateToHoldingTank()

        		    when SharedLib::StopFromPc
            		    bbbLog("FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}")
            		    `echo "#{Time.new.inspect} : FATAL ERROR inconsistent - From BBB::IDLE setting to BBB::STOP #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                    when SharedLib::PcCmdNotSet
                        #
                        # We're in idle mode, increase interval of monitoring of any commands coming from the Pc
                        #
            		    bbbLog("Staying in Idle Mode - GetPcCmd() = '#{SharedMemory.GetPcCmd()}'")
            		else
            		    SharedMemory.SetPcCmd(SharedLib::PcCmdNotSet,"#{__LINE__}-#{__FILE__}")
            		    bbbLog("Staying in Idle Mode - unknown PC Command '#{SharedMemory.GetPcCmd()}'")
            		    `echo "#{Time.new.inspect} : mode='#{SharedMemory.GetPcCmd()}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
            		end
        		end
            else
			    SharedMemory.SetBbbMode(SharedLib::InIdleMode,"#{__LINE__}-#{__FILE__}")
                `echo "#{Time.new.inspect} : mode='#{SharedMemory.GetBbbMode()}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                setPollIntervalInSeconds(1)
            end						
            
            if SharedMemory.GetBbbMode() != SharedMemory::InRunMode
                puts "In idle mode..."
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

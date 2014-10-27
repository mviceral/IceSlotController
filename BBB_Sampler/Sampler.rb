# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'timeout'
require 'beaglebone'
require_relative 'DutObj'
require_relative 'ThermalSiteDevices'
require_relative "../lib/BBB_GPIO2 Interface Ruby/GPIO2"
require_relative '../lib/SharedLib'
require_relative "../BBB_Sender/SendSampledTcuToPcLib"
require 'singleton'
require 'forwardable'
require 'thread'
require 'json'

# DRuby stuff
require 'drb/drb'
SERVER_URI="druby://localhost:8787"

include Beaglebone

TOTAL_DUTS_TO_LOOK_AT  = 24

class TCUSampler
    SlotBibNum = "SLOT BIB#"
    LastStepNumOfSentLog = "LastStepNumOfSentLog"
    Steps = "Steps"
    FileName = "FileName"
    Configuration = "Configuration"
    HighestStepNumber = "HighestStepNumber"
    StepTimeLeft = "StepTimeLeft"
    TimeOfRun = "TimeOfRun"
    StepTime = "Step Time"
    StepNum = "Step Num"
    ForPowerSupply = "ForPowerSupply"
    PollIntervalInSeconds = "PollIntervalInSeconds"   
    HoldingTankFilename = "MachineState_DoNotDeleteNorModify.json"
    FaultyTcuList_SkipPolling = "../TcuDisabledSites.txt"
    BbbMode = "BbbMode"
    SDDlyms = "SDDlyms"
    SeqDownPsArr = "SeqDownPsArr"
    SUDlyms = "SUDlyms"
    SeqUpPsArr = "SeqUpPsArr"
	CalculatedTempWait = "CalcTW"
    
    NomSet = "NomSet"
    
    # IntervalSecInStopMode = 1
    # IntervalSecInRunMode = 10

    # Variables used for log file
    PSNameLogger = "  Name"
    NomSetLogger = "NomSet"
    TripMinLogger = "TripMin"
    TripMaxLogger = "TripMax"
    FlagTolPLogger = "FlagTolP"
    FlagTolNLogger = "FlagTolN"
    MaxTolI =        "FlagTolI"
    MaxTripI =       "TripMaxI"
    SeqUpLogger = "SeqUp"
    SeqDownLogger = "SeqDown"
    SDDlyms = "SDDlyms"
    SUDlyms = "SUDlyms"
    VMeas = "VMeas"
    IMeas = "IMeas"
    Temp1 = " Temp1"
    Temp2 = " Temp2"
    
    DutNum= " DUT#"
    DutStatus = "        DUT status"
    DutTemp = "  Temp"
    DutCurrent = "Current"
    DutHeatDuty = "HEAT duty%"
    DutCoolDuty = "COOL duty%"
    DutControllerTemp = "Controller temp"

    FIXNUM_MAX = (2**(0.size * 8 -2) -1) # Had to get its value one time.  Might still be useful.

    # Columns used for bbbDefault
    IndexCol = 0
	NameCol = 1
	NomSetCol = 4
	TripMinCol = 5
	TripMaxCol = 6
	FlagTolPCol = 7 # Flag Tolerance Positive
	FlagTolNCol = 8 # Flag Tolerance Negative
	EnableBitCol = 9 # Flag indicating that software can turn it on or off
	IdleStateCol = 10 # Flag indicating that software can turn it on or off
	LoadStateCol = 11 # Flag indicating that software can turn it on or off
	StartStateCol = 12 # Flag indicating that software can turn it on or off
	RunStateCol = 13 # Flag indicating that software can turn it on or off
	StopStateCol = 14 # Flag indicating that software can turn it on or off
	ClearStateCol = 15 # Flag indicating that software can turn it on or off
	LocationCol = 16 # Flag indicating that software can turn it on or off

    
    class PsSeqItem
        EthernetOrSlotPcb = "EthernetOrSlotPcb"
        EthernetOrSlotPcb_Ethernent = "Ethernent"
        EthernetOrSlotPcb_SlotPcb = "Slot PCB"
        SeqUp = "SeqUp"
        SUDlyms = "SUDlyms"
        SocketIp = "SocketIp"
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


    # Special note regarding file openTtyO1Port_115200.exe, this comes from the folder BBB_openTtyO1Port c code, and 
    # it's compiled as an executable.
    #
    # system("./openTtyO1Port_115200.exe")
    include Singleton
    include Beaglebone

    def setTimeOfPcUpload(timeInIntegerParam)
        @boardData[TimeOfPcUpload] = timeInIntegerParam
    end
	
	def getTimeOfRun
        if @boardData[TimeOfRun].nil?
            @boardData[TimeOfRun] = Time.now.to_i
        end
        return @boardData[TimeOfRun]
    end
    
    def setTimeOfRun
        @boardData[TimeOfRun] = Time.now.to_f
    end
    
    def setToMode(modeParam, calledFrom)
        @samplerData.SetBbbMode(modeParam,"called from #{calledFrom} #{__LINE__}-#{__FILE__}")
        @boardData[BbbMode] = modeParam
        @boardMode = modeParam

        
        #
        # The mode of the board change, log it and save the save of the machine to holding tank.
        #
        SharedLib.bbbLog("Changed to '#{modeParam}' called from [#{calledFrom}].  Saving state to holding tank.")
        if modeParam == SharedLib::InRunMode || modeParam == SharedLib::InStopMode
            if modeParam == SharedLib::InRunMode
                runMachine()
                turnOnHeaters()
                psSeqUp()
                setTimeOfRun()
                # setPollIntervalInSeconds(IntervalSecInRunMode,"#{__LINE__}-#{__FILE__}")
            else
                # setPollIntervalInSeconds(IntervalSecInStopMode,"#{__LINE__}-#{__FILE__}")

                # Turn on the control for TCUs that are not disabled.
                setTcuToStopMode() # turnOffDuts(@tcusToSkip)
                
                turnOffHeaters()

                @samplerData.setWaitTempMsg("")
                @samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
    

                #
                # Calculate the total time left before sequencing down.
                #
                if @stepToWorkOn.nil? == false
                    @stepToWorkOn[StepTimeLeft] = @stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun())
                end
                psSeqDown("#{__LINE__}-#{__FILE__}")
            end
            
            saveBoardStateToHoldingTank()
        else
            SharedLib.bbbLog("Don't recognize modeParam=#{modeParam}, calledFrom=#{calledFrom}")
            SharedLib.bbbLog("Exiting code.")
            exit
        end
    end
    
    def getConfiguration()
        @boardData[Configuration]
    end

    def psSeqDown(fromParam)
        # puts "psSeqDown fromParam = '#{fromParam}'"
        doPsSeqPower(false)
    end
    
    def psSeqUp()
        doPsSeqPower(true)
    end
    
    def getEthernetPsCurrent
        if @eIps.nil?
            @eIps = Hash.new
        end
        
        sortedUp = getSeqUpPsArr()
        if sortedUp.nil? == false
            sortedUp.each do |psItem|
                # puts psItem
                # puts "psItem.keyName=#{psItem.keyName}, psItem.seqOrder=#{psItem.seqOrder}"
                if psItem.seqOrder != 0
                    if @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_Ethernent
                        #
                        # Do ethernet power supply enabling/disabling here.
                        #
                        # puts "Ethernet PS key isolated = '#{psItem.keyName[1..-1]}' ip address of PS '#{@ethernetScheme[psItem.keyName[1..-1]]}'"
                        if @socketIp.nil? == false
                            if @socketIp[@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]].nil? == false
                                begin
                                    host = @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]
                                    @socketIp[host].print("MEAS:CURR?\r\n")
                                    tmp = @socketIp[@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]].recv(256)
                                    @eIps[psItem.keyName[1..-1]] = tmp
                                    rescue Exception => e  
                                        @socketIp[host].close # Close the socket since there was a failure.
                                        SharedLib.bbbLog "e.message=#{e.message }"
                                        SharedLib.bbbLog "e.backtrace.inspect=#{e.backtrace.inspect}" 
                                        
                                        # See if it can reconnect...
                                        port = 5025
                                        SharedLib.bbbLog "Reconnect Ethernet PS at IP 'host'" 
                                        @socketIp[host] = TCPSocket.open(host,port)
                                end
                                # puts "measured I='#{tmp[0..-2]}' from IP='#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]}' #{__LINE__}-#{__FILE__}"
                            else
                                # SharedLib.bbbLog "Socket on '#{psItem.keyName[1..-1]}' ip address '#{@ethernetScheme[psItem.keyName[1..-1]].chomp}' is not yet initialized.  Reload 'Steps' file."
                            end
                        else
                            # SharedLib.bbbLog "Ethernet power supplies are not initialized.  Reload steps configuration file."
                        end
                    end
                end
            end        
        end
        @samplerData.WriteDataEips(@eIps,"#{__LINE__}-#{__FILE__}")
    end
    
    def doPsSeqPower(powerUpParam)
        # PS sequence gets called twice sometimes.
        # puts "@boardData[\"LastPsSeqStateCall\"]=#{@boardData["LastPsSeqStateCall"]}, powerUpParam=#{powerUpParam} #{__LINE__}-#{__FILE__}" 
        if @boardData["LastPsSeqStateCall"] == powerUpParam
            return
        else
            @boardData["LastPsSeqStateCall"] = powerUpParam
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
            # puts psItem
            # puts "psItem.keyName=#{psItem.keyName}, psItem.seqOrder=#{psItem.seqOrder}"
            if psItem.seqOrder != 0
                puts "Turning '#{textDisp}' PS item '#{psItem.keyName}' #{@stepToWorkOn["PsConfig"][psItem.keyName]}"
                if @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_Ethernent
                    #
                    # Do ethernet power supply enabling/disabling here.
                    #
                    # puts "Ethernet PS key isolated = '#{psItem.keyName[1..-1]}' ip address of PS '#{@ethernetScheme[psItem.keyName[1..-1]]}'"
                    puts "checking IP of socket = '#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]}'"
                    if @socketIp.nil? == false
                        if @socketIp[@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]].nil? == false
                            if powerUpParam
                                @socketIp[@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]].print("OUTP:POW:STAT ON\r\n")
                            else
                                @socketIp[@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SocketIp]].print("OUTP:POW:STAT OFF\r\n")
                            end
                        else
                            SharedLib.bbbLog "Socket on '#{psItem.keyName[1..-1]}' ip address '#{@ethernetScheme[psItem.keyName[1..-1]].chomp}' is not yet initialized.  Reload 'Steps' file."
                        end
                    else
                        SharedLib.bbbLog "@socketIp is nil!!!!."
                    end
                elsif @stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_SlotPcb
                    if @setupAtHome == false
                        case psItem.keyName
                        when PsSeqItem::SPS6
                        # SharedLib::pause "Called #{PsSeqItem::SPS6}", "#{__LINE__}-#{__FILE__}"
                        if powerUpParam
                            # SharedLib::pause "Powering UP", "#{__LINE__}-#{__FILE__}"
                            @gPIO2.setBitOn((GPIO2::PS_ENABLE_x3).to_i,(GPIO2::W3_PS6).to_i)
                        else
                            # SharedLib::pause "Powering DOWN", "#{__LINE__}-#{__FILE__}"
                            @gPIO2.setBitOff((GPIO2::PS_ENABLE_x3).to_i,(GPIO2::W3_PS6).to_i)
                        end
                        
                        when PsSeqItem::SPS8
                            if powerUpParam
                                @gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS8)
                            else
                                @gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS8)
                            end
                        when PsSeqItem::SPS9
                            if powerUpParam
                                @gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS9)
                            else
                                @gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS9)
                            end
                        when PsSeqItem::SPS10
                            if powerUpParam
                                @gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS10)
                            else
                                @gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_PS10)
                            end
                        else
                            `echo "#{Time.new.inspect} : psItem.keyName='#{psItem.keyName}' not recognized.  #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
                        end
                    end
                else
                    SharedLib.bbbLog "@stepToWorkOn[\"PsConfig\"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb]='#{@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::EthernetOrSlotPcb]}' not recognized.  #{__LINE__}-#{__FILE__}"
                end
                
                if powerUpParam
                    sleep((@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SUDlyms].to_i)/1000)
                    puts "sleep for '#{(@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SUDlyms].to_i)}'"
                else
                    sleep((@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SDDlyms].to_i)/1000)
                    puts "sleep for '#{(@stepToWorkOn["PsConfig"][psItem.keyName][PsSeqItem::SDDlyms].to_i)}'"
                end
                # sleep(3)
            end
        end
    end

    def saveBoardStateToHoldingTank()
	    # Write configuartion to holding tank case there's a power outage.
	    if @stepToWorkOn.nil? == false
	        # PP.pp(@stepToWorkOn)
            @samplerData.SetStepNumber(@stepToWorkOn["Step Num"])
            @samplerData.SetStepTimeLeft(@stepToWorkOn[StepTimeLeft])
        else
            @samplerData.SetAllStepsCompletedAt(@boardData[SharedLib::AllStepsCompletedAt])
	        # SharedLib.pause "PP @stepToWorkOn","#{__LINE__}-#{__FILE__}"
	    end

        # PP.pp(@boardData)
        # SharedLib.pause "Checking @boardData","#{__LINE__}-#{__FILE__}"
	    File.open(HoldingTankFilename, "w") { 
	        |file| file.write(@boardData.to_json) 
        }
    end

    def getPollIntervalInSeconds()
        if @boardData[PollIntervalInSeconds].nil?
            @boardData[PollIntervalInSeconds] = 1
        end
        # puts "getPollIntervalInSeconds=#{@boardData[PollIntervalInSeconds]} #{__LINE__}-#{__FILE__}"
        return @boardData[PollIntervalInSeconds]
    end

=begin    
    def setPollIntervalInSeconds(timeInSecParam,fromParam)
        # puts "setPollIntervalInSeconds=#{timeInSecParam} [#{fromParam}] #{__LINE__}-#{__FILE__}"
        @boardData[PollIntervalInSeconds] = timeInSecParam
    end
=end

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
        if @stepToWorkOn.nil?
            return nil # All steps are done.
        end
        
	    objWithSeq = Hash.new
	    @stepToWorkOn["PsConfig"].each do |key, array|
            # puts "#{key}-----"
	        @stepToWorkOn["PsConfig"][key].each do |key2, array|
	            if key2 == "SeqUp"
	                objWithSeq[key] = @stepToWorkOn["PsConfig"][key]
	            end
	            # puts "  #{key2}-----"
	        end
        end
        
        largestSeqNum = 0
        # puts "Checking isolated objects with sequences as sub parts."
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
        
        # Get the disabled PS for cross check on trip Voltages.
        if @disabledPS.nil?
            @disabledPS = Array.new
            ct = 0
            while ct < sortedUp.length
                if sortedUp[ct].seqOrder == 0
                    @disabledPS.push("V"+sortedUp[ct].keyName[1..-1])
                    @disabledPS.push("I"+sortedUp[ct].keyName[1..-1]) # don't check for current also.
                end
                ct += 1
            end
        end
        
        return sortedUp
    end
    
    def openEthernetPsSocket(host,port)
        if @ethernetPS.nil?
            @ethernetPS = Hash.new
        end
        
        if @ethernetPS[host].nil?
            @ethernetPS[host] = true


            if @setupAtHome
                puts "Skipping PS host='#{host}' setup due to @setupAtHome == true."
                @socketIp[host] = nil
            else
                tries = 0
                goodConnection = false
                while tries<5 && goodConnection == false
                    begin
                        @socketIp[host] = TCPSocket.open(host,port)
                        goodConnection = true
                        rescue
                            SharedLib.bbbLog("Failed to connect on Ethernet power supply IP='#{host}'.  Attempt #{(tries+1)} of 5  #{__LINE__}-#{__FILE__}")
                            sleep(0.25)
                    end
                    tries += 1
                end
                
                if tries == 5
                    @socketIp[host] = nil
                    # Show a message to the PC that Ethernet PS on IP=host can't be accessed.  Show the time too of incident too.
                    @samplerData.ReportError("Cannot open Ethernet power supply socket on IP='#{host}'.  This power supply will be disabled.",Time.new)
                	SendSampledTcuToPCLib::SendDataToPC(@samplerData,"#{__LINE__}-#{__FILE__}")
                end
            end
        end
    end
    
    def checkOkToLog
        if @boardData[LastStepNumOfSentLog].nil? == false &&  @boardData[HighestStepNumber].nil? == false
            lastStepNumOfSentLog = @boardData[LastStepNumOfSentLog].to_i
            if  (1 <= lastStepNumOfSentLog && lastStepNumOfSentLog <= @boardData[HighestStepNumber])
                return true
            end
        end
        return false
    end

    def initStepToWorkOnVar(uart1)
        if @logRptAvg.nil? == false
            # Reports the last data gathered from the step.
            if @isOkToLog
                getSystemStateAvgForLogging()
                sendToLogger("End Step (step##{@boardData[LastStepNumOfSentLog]})\n")
            end
        end


        @disabledPS = nil # clears out the list when gathering data for the new step
        @samplerData.SetStepTimeLeft("")
        @samplerData.SetStepName("")
        @samplerData.SetStepNumber("")
        @samplerData.SetTotalTimeOfStepsInQueue(0.0)
        # puts "\n\n\ninitStepToWorkOnVar got called."
        # puts caller
        @stepToWorkOn = nil

        # Setup the @stepToWorkOn
	    stepNumber = 0
        timerRUFP = 0
        timerRDFP = 0

	    # puts "getConfiguration().nil? = #{getConfiguration().nil?}  #{__LINE__}-#{__FILE__}"
	    while getConfiguration().nil? == false && getConfiguration()["Steps"].nil? == false && 
	    	stepNumber<getConfiguration()["Steps"].length && 
	    	@stepToWorkOn.nil?
	    	# puts "A0 #{__LINE__}-#{__FILE__}"
	        if @stepToWorkOn.nil?
	            # puts "A1 #{__LINE__}-#{__FILE__}"
                getConfiguration()[Steps].each do |key, array|
		            if @stepToWorkOn.nil?
                        getConfiguration()[Steps][key].each do |key2, array2|
                            # Get which step to work on and setup the power supply settings.
                            if key2 == StepNum 
                                if getConfiguration()[Steps][key][key2].to_i == (stepNumber+1) 
                                    # puts "A3 getConfiguration()[Steps][key][key2].to_i=#{getConfiguration()[Steps][key][key2].to_i} (stepNumber+1) =#{(stepNumber+1) } #{__LINE__}-#{__FILE__}"
                                    # puts "A4 getConfiguration()[Steps][key][StepTimeLeft].to_i=#{getConfiguration()[Steps][key][StepTimeLeft].to_i} #{__LINE__}-#{__FILE__}"
                                    if getConfiguration()[Steps][key][StepTimeLeft].to_i > 0
                                        # This is the step we want to work on.  Set the temperature settings.
                                        # PP.pp(getConfiguration()[Steps][key]["TempConfig"])
                                        # puts "Checking content of 'TempConfig' #{__LINE__}-#{__FILE__}"
                                        sleep(2.0)
                                        @tempSetPoint = getConfiguration()[Steps][key]["TempConfig"]["TDUT"]["NomSet"]
                                        ThermalSiteDevices.setTHCPID(uart1,"T",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["TDUT"]["NomSet"])
                                        ThermalSiteDevices.setTHCPID(uart1,"H",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["H"][0..-2].to_f/100.0*255)
                                        ThermalSiteDevices.setTHCPID(uart1,"C",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["C"][0..-2].to_f/100.0*255)
                                        ThermalSiteDevices.setTHCPID(uart1,"P",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["P"])
                                        ThermalSiteDevices.setTHCPID(uart1,"I",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["I"])
                                        ThermalSiteDevices.setTHCPID(uart1,"D",@tcusToSkip,getConfiguration()[Steps][key]["TempConfig"]["D"])


                                        # puts "P = '#{getConfiguration()[Steps][key]["TempConfig"]["P"]}'"
                                        # puts "I = '#{getConfiguration()[Steps][key]["TempConfig"]["I"]}'" 
                                        # puts "D = '#{getConfiguration()[Steps][key]["TempConfig"]["D"]}'"
                                        
                                        # Make sure all the duts have the settings PIDTH we sent.
                                        SharedLib.bbbLog "Turning on controllers.  #{__LINE__}-#{__FILE__}"
                                        ct = 0
                                        while ct<24 do
                                            if @tcusToSkip[ct].nil? == true
                                                vStatus = DutObj::getTcuStatusV(ct, uart1,@gPIO2)
                                                SharedLib.bbbLog("Code not done.  Make sure that the vStatus are what was set to be.  Try to set for 5 times.  If failed, add to @tcusToSkip list, and report an error. #{__LINE__}-#{__FILE__}")
                                            end
                                            ct += 1
                                        end
                                        
                                        setAllStepsDone_YesNo(SharedLib::No,"#{__LINE__}-#{__FILE__}")
                                        @stepToWorkOn = getConfiguration()[Steps][key]
                                        
                                        @dutTempTripMin = @stepToWorkOn["TempConfig"]["TDUT"]["TripMin"]
                                        @dutTempTripMax = @stepToWorkOn["TempConfig"]["TDUT"]["TripMax"]
                                        if (@dutTempTripMin<@dutTempTripMax) == false
                                            # Just make sure that these numbers are as stated @dutTempTripMin<@dutTempTripMax
                                            hold = @dutTempTripMin
                                            @dutTempTripMin = @dutTempTripMax
                                            @dutTempTripMax = hold
                                        end
                                        # PP.pp(@stepToWorkOn)
                                        # SharedLib.pause "Checking content of @stepToWorkOn","#{__LINE__}-#{__FILE__}"
                                        # puts "TIMERRUFP = '#{getConfiguration()[Steps][key]["TempConfig"]["TIMERRUFP"]}'"
                                        # puts "TIMERRDFP = '#{getConfiguration()[Steps][key]["TempConfig"]["TIMERRDFP"]}'"

                                        timerRUFP = getConfiguration()[Steps][key]["TempConfig"]["TIMERRUFP"]
                                        timerRDFP = getConfiguration()[Steps][key]["TempConfig"]["TIMERRDFP"]

                                        @samplerData.SetStepName("#{key}")
                                        @samplerData.SetStepNumber("#{stepNumber+1}")

                        		        # Setup the power supplies...
                                        @stepToWorkOn["PsConfig"].each do |key, data|
                                            # puts "key='#{key}' #{__LINE__}-#{__FILE__}"
                                            if key[0..1] == "VP"
                                                sequencePS = "S#{key[1..-1]}"
                                                # puts "sequencePS='#{sequencePS}' is '#{PsSeqItem::EthernetOrSlotPcb_Ethernent}' #{__LINE__}-#{__FILE__}"
                                                if @stepToWorkOn["PsConfig"][sequencePS][PsSeqItem::EthernetOrSlotPcb] == PsSeqItem::EthernetOrSlotPcb_Ethernent 
                                                    if @stepToWorkOn["PsConfig"][sequencePS][PsSeqItem::SeqUp].to_i > 0
                                                        # puts "SeqUp value = '#{@stepToWorkOn["PsConfig"][sequencePS][PsSeqItem::SeqUp]}' #{__LINE__}-#{__FILE__}"
                                                        # Setup a connetion to the PS via ethernet, and set the voltage and current settings
                                                        if @socketIp.nil?
                                                            @socketIp = Hash.new
                                                        end
                                                        host = @ethernetScheme[key[1..-1]].chomp
                                                        port = 5025                # port
                                                        if @socketIp[host].nil?
                                                            # puts "host = '#{host}',port = '#{port}' #{__LINE__}-#{__FILE__}"
                                                            openEthernetPsSocket(host,port)
                                                        end
                                                        @stepToWorkOn["PsConfig"][sequencePS][PsSeqItem::SocketIp] = @ethernetScheme[key[1..-1]].chomp
                    
                                                        if @socketIp[host]
                                                            # Set the voltage
                                                            # puts "voltage name = '#{key}', NomSet=#{@stepToWorkOn["PsConfig"][key][NomSet]} #{__LINE__}-#{__FILE__}"
                                                            # print "VNomSet=#{@stepToWorkOn["PsConfig"][key][NomSet]} "
                                                            @socketIp[host].print("SOUR:VOLT #{@stepToWorkOn["PsConfig"][key][NomSet]}\r\n")
                        
                                                            # Set the current
                                                            # puts "current name = 'I#{key[1..-1]}', NomSet=#{@stepToWorkOn["PsConfig"]["I#{key[1..-1]}"][NomSet]} #{__LINE__}-#{__FILE__}"
                                                            # puts "INomSet=#{@stepToWorkOn["PsConfig"]["I#{key[1..-1]}"][NomSet]} #{__LINE__}-#{__FILE__}"
                                                            @socketIp[host].print("SOUR:CURR #{@stepToWorkOn["PsConfig"]["I#{key[1..-1]}"][NomSet]}\r\n")
                                                            # SharedLib.pause "Checking value of @stepToWorkOn","#{__LINE__}-#{__FILE__}"
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                        
                                        # SharedLib.pause "A Got a step", "#{__LINE__}-#{__FILE__}"
                                        # PP.pp(@stepToWorkOn)
                                        # SharedLib.pause "B Got a step Breaking out of loop.", "#{__LINE__}-#{__FILE__}"
                                    end
                                end
                            end
                            # puts "C #{__LINE__}-#{__FILE__}"
                        end
                        # puts "D #{__LINE__}-#{__FILE__}"
		            end
		            # puts "E #{__LINE__}-#{__FILE__}"
                end
                # puts "F #{__LINE__}-#{__FILE__}"
	        end
	        # puts "G #{__LINE__}-#{__FILE__}"
	        stepNumber += 1
	    end

        # Setup the total time still to go on the step queue
        hash = Hash.new
	    stepNumber = 0
	    # puts "getConfiguration().nil? = #{getConfiguration().nil?}  #{__LINE__}-#{__FILE__}"
	    while getConfiguration().nil? == false && getConfiguration()["Steps"].nil? == false && 
	    	stepNumber<getConfiguration()["Steps"].length 
	    	# puts "A0 #{__LINE__}-#{__FILE__}"
            # puts "A1 #{__LINE__}-#{__FILE__}"
            getConfiguration()[Steps].each do |key, array|
                getConfiguration()[Steps][key].each do |key2, array2|
                    # Get the total time of Steps in queue
                    if key2 == StepNum 
                        if @stepToWorkOn != getConfiguration()[Steps][key]
                            if getConfiguration()[Steps][key][StepTimeLeft].to_i > 0 && hash[key].nil?
                                puts "Add time #{getConfiguration()[Steps][key][StepTimeLeft]} key='#{key}' @samplerData.GetTotalTimeOfStepsInQueue()='#{@samplerData.GetTotalTimeOfStepsInQueue()}'"
                                hash[key] = key
                                @samplerData.SetTotalTimeOfStepsInQueue(getConfiguration()[Steps][key][StepTimeLeft].to_f+@samplerData.GetTotalTimeOfStepsInQueue().to_f)
                                puts "New total @samplerData.GetTotalTimeOfStepsInQueue()='#{@samplerData.GetTotalTimeOfStepsInQueue()}'"
                            end
                        end
                    end
                end
	            # puts "E #{__LINE__}-#{__FILE__}"
            end
	        # puts "G #{__LINE__}-#{__FILE__}"
	        stepNumber += 1
	    end
	    
        if @stepToWorkOn.nil? == false
            @stepToWorkOn["TIMERRUFP"] = timerRUFP
            @stepToWorkOn["TIMERRDFP"] = timerRDFP
            @stepToWorkOn[CalculatedTempWait] = @stepToWorkOn[SharedMemory::TempWait].to_f*60

            if @boardData[LastStepNumOfSentLog] != @samplerData.GetStepNumber()
                @boardData[LastStepNumOfSentLog] = @samplerData.GetStepNumber()
                @isOkToLog = checkOkToLog()
                
                # If step number is not numeric, don't process code below.
                stepnumber = @samplerData.GetStepNumber().to_i
                
=begin
                if @boardData[HighestStepNumber].nil? == false
                    puts "stepnumber='#{stepnumber}', 1<= #{stepnumber} && #{stepnumber} <= #{@boardData[HighestStepNumber]} = '#{1<= stepnumber && stepnumber <= @boardData[HighestStepNumber]}'"
                    SharedLib.pause "Checking values listed.","#{__LINE__}-#{__FILE__}"
                end
=end

                if @boardData[HighestStepNumber].nil? == false && 1<= stepnumber && stepnumber <= @boardData[HighestStepNumber]
                    @timeOfLog = Time.new.to_i
                    if @loggingTime.nil?
                        @loggingTime = 60
                    end
                    @timeOfLog += @loggingTime
                    @logRptAvgCt = 0
                    @logRptAvg = nil
                    
                    puts "Sending log data.  #{Time.now.inspect}. #{__LINE__}-#{__FILE__}"
                    # tbs  = "BIB#: #{@ethernetScheme[SlotBibNum]}\n"
                    tbs = ""
                    tbs += "Test Step: step##{@samplerData.GetStepNumber()}-#{@samplerData.GetStepName()}  Time: #{Time.now.inspect}\n"
                    tbs += "Power Supply Settings:\n"
                    tbs += "#{PSNameLogger}|#{NomSetLogger}|#{TripMinLogger}|#{TripMaxLogger}|#{FlagTolPLogger}|#{FlagTolNLogger}|#{MaxTolI}|#{MaxTripI}|#{SeqUpLogger}|#{SUDlyms}|#{SeqDownLogger}|#{SDDlyms}\n"
                    @stepToWorkOn["PsConfig"].each do |key, array|
                        if key[0] == "V"
                            tbs += "#{makeItFit(key,PSNameLogger)}|"
                            tbs += "#{makeItFitMeas(array["NomSet"],6,NomSetLogger)}|"
                            tbs += "#{makeItFitMeas(array["TripMin"],6,TripMinLogger)}|"
                            tbs += "#{makeItFitMeas(array["TripMax"],6,TripMaxLogger)}|"
                            tbs += "#{makeItFitMeas(array["FlagTolP"],6,FlagTolPLogger)}|"
                            tbs += "#{makeItFitMeas(array["FlagTolN"],6,FlagTolNLogger)}|"
    
                            keyName = "I#{key[1..-1]}"
                            maxTolI = @stepToWorkOn["PsConfig"][keyName]["FlagTolN"]
                            tbs += "#{makeItFitMeas(maxTolI,6,MaxTolI)}|"
                            
                            maxTripI = @stepToWorkOn["PsConfig"][keyName]["TripMax"]
                            tbs += "#{makeItFitMeas(maxTripI,6,MaxTripI)}|"
    
                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]]["SeqUp"],SeqUpLogger)}|"
                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]][PsSeqItem::SUDlyms],SUDlyms)}|"
                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]]["SeqDown"],SeqDownLogger)}|"
                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]][PsSeqItem::SDDlyms],SDDlyms)}\n"
                        end
                    end
                    tbs += "Temperature Setting:\n"
                    tbs += "#{PSNameLogger}|#{NomSetLogger}|#{TripMinLogger}|#{TripMaxLogger}|#{FlagTolPLogger}|#{FlagTolNLogger}\n"
                    @stepToWorkOn["TempConfig"].each do |key, array|
                        if key == "TDUT"
                            tbs += "#{makeItFit(key,PSNameLogger)}|"
                            tbs += "#{makeItFitMeas(array["NomSet"],6,NomSetLogger)}|"
                            tbs += "#{makeItFitMeas(array["TripMin"],6,TripMinLogger)}|"
                            tbs += "#{makeItFitMeas(array["TripMax"],6,TripMaxLogger)}|"
                            tbs += "#{makeItFitMeas(array["FlagTolP"],6,FlagTolPLogger)}|"
                            tbs += "#{makeItFitMeas(array["FlagTolN"],6,FlagTolNLogger)}\n"
                        end
                    end
                    sendToLogger(tbs)
                end
            end

        end
    end

    def setBoardStateForCurrentStep(uart1)
        @boardData[SeqDownPsArr] = nil
        @boardData[SeqUpPsArr] = nil
        initStepToWorkOnVar(uart1)
        getSeqDownPsArr()
        getSeqUpPsArr()

        if @boardData[BbbMode] == SharedLib::InStopMode
            # Run the sequence down process on the system
            psSeqDown("#{__LINE__}-#{__FILE__}")
            # setPollIntervalInSeconds(IntervalSecInStopMode,"#{__LINE__}-#{__FILE__}")
        else
            # Run the sequence up process on the system
            psSeqUp()
            # setPollIntervalInSeconds(IntervalSecInRunMode,"#{__LINE__}-#{__FILE__}")
        end
        # @samplerData.SetBbbMode(@boardData[BbbMode],"#{__LINE__}-#{__FILE__}")
    end
    
    def runMachine()
        @waitTempStartTime = Time.now.to_f
        
        @dutTempTolReached = Hash.new
        @allDutTempTolReached = false
                				
        # Turn on the control for TCUs that are not disabled.
        SharedLib.bbbLog "Turning on controllers.  #{__LINE__}-#{__FILE__}"
        ct = 0
        while ct<24 do
            if @tcusToSkip[ct].nil? == true
                bitToUse = etsEnaBit(ct)
                if 0<=ct && ct <=7  
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna1Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna1SetOn(bitToUse)
                elsif 8<=ct && ct <=15
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna2Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna2SetOn(bitToUse)
                elsif 16<=ct && ct <=23
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna3Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna3SetOn(bitToUse)
                end
            end
            ct += 1
        end
    end
    
    def setErrorColorFlagBase(key2)
        if @boardData[SharedMemory::ErrorColor].nil?
            @boardData[SharedMemory::ErrorColor] = Hash.new
        end
        
        if @boardData[SharedMemory::ErrorColor][key2].nil?
            @boardData[SharedMemory::ErrorColor][key2] = Hash.new
        end
    end
    
    def setErrorColorFlag(key2,flag)
        setErrorColorFlagBase(key2)

        if @boardData[SharedMemory::ErrorColor][key2][SharedMemory::Latch].nil?
            @boardData[SharedMemory::ErrorColor][key2][SharedMemory::Latch] = flag
        elsif @boardData[SharedMemory::ErrorColor][key2][SharedMemory::Latch] < flag
            @boardData[SharedMemory::ErrorColor][key2][SharedMemory::Latch] = flag
        end

        @boardData[SharedMemory::ErrorColor][key2][SharedMemory::CurrentState] = flag

        @samplerData.setErrorColor(@boardData[SharedMemory::ErrorColor])
    end

    
    def stopMachineIfTripped(gPIO2Param, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
        if @disabledPS.include?(key2) == false
            # puts "'#{key2}' is not disabled.  Checking for trip points."
            # if (key2 == "VPS3")
            #     puts("key2 = #{key2}, tripMin='#{tripMin}', actualValue='#{actualValue}', tripMax='#{tripMax}', flagTolP='#{flagTolP}', flagTolN='#{flagTolN}'")
            # end
            
            unit = key2[0]
            if unit == "I"
                unit = "A"
            end
            
            if (flagTolP <= actualValue && actualValue <= flagTolN) == false
                @samplerData.ReportError("NOTICE - #{key2} out of bound flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed..\n",Time.new)
                setErrorColorFlag(key2,SharedMemory::OrangeFlag)
                
                if (tripMin <= actualValue && actualValue <= tripMax) == false
                    if is2ndFault(key2,unit,tripMin,actualValue,tripMax)
                        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
                        # Turn on red light and buzzer and make it blink due to shutdown
                        setToAlarmMode()
                        tbs = "ERROR - #{key2} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE.\n"
                        timeOfError = Time.new
                        @samplerData.ReportError(tbs,timeOfError)
                        @samplerData.setStopMessage("Trip Point Error, Stopped.")
                        setErrorColorFlag(key2,SharedMemory::RedFlag)
                        logSystemStateSnapShot(tbs,timeOfError)
                        return true                
                    end
                end
            else
                setErrorColorFlag(key2,SharedMemory::GreenFlag)
                clearFault(key2)
            end
        end
        return false
    end
    
    def setBoardData(boardDataParam,uart1)
        # The configuration was just loaded from file.  We must setup the system to be in a given state.
        # For example, if the system is in runmode, when starting the system over, the PS must sequence up
        # properly then set the system to run mode.
        # if the system is in idle mode, make sure to run the sequence down on power supplies.
        # The file in the hard drive only stores two states of the system: running or in idle.
        @boardData = boardDataParam
        if getConfiguration().nil? == false
            setBoardStateForCurrentStep(uart1)
        end
    end

=begin    
    def runThreadForPcCmdInput()
        # puts "A Running 'runThreadForPcCmdInput()'"
        pcCmdInput = Thread.new do
            # puts "B Running 'runThreadForPcCmdInput()'"
            server = TCPServer.open(2000)  # Socket to listen on port 2000
            loop {                         # Servers run forever
                # puts "C Running 'runThreadForPcCmdInput()'"
                client = server.accept       # Wait for a client to connect
                @mutex.synchronize do
                    puts "D Running 'runThreadForPcCmdInput()'"
                    clientStr = client.gets.chomp
                    puts "E uritostr = '#{clientStr}'"
                    hashSocket = JSON.parse(clientStr)
                    puts "f uritostr = '#{clientStr}'"
                    mode = hashSocket["Cmd"]
                    hash = hashSocket["Data"]
					@samplerData.SetSlotOwner(hash["SlotOwner"])
                    puts "mode='#{mode}'"
					case mode
					when SharedLib::ClearConfigFromPc
						@samplerData.ClearConfiguration("#{__LINE__}-#{__FILE__}")
						# return {bbbResponding:"#{SendSampledTcuToPCLib.GetDataToSendPc(sharedMem)}"}						
					when SharedLib::RunFromPc
					when SharedLib::StopFromPc
					when SharedLib::LoadConfigFromPc
						puts "LoadConfigFromPc code block got called. #{__LINE__}-#{__FILE__}"
						# puts "hash=#{hash}"
						puts "SlotOwner=#{hash["SlotOwner"]}"
						date = Time.at(hash[SharedLib::ConfigDateUpload])
						#puts "PC time - '#{date.strftime("%d %b %Y %H:%M:%S")}'"
						# Sync the board time with the pc time
						`echo "date before setting:";date`
						`date -s "#{date.strftime("%d %b %Y %H:%M:%S")}"`
						`echo "date after setting:";date`
						@samplerData.SetConfiguration(hash,"#{__LINE__}-#{__FILE__}")
						# return {bbbResponding:"#{SendSampledTcuToPCLib.GetDataToSendPc(sharedMem)}"}						
					else
						`echo "#{Time.new.inspect} : mode='#{mode}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
					end
					@samplerData.SetPcCmd(mode,"#{__LINE__}-#{__FILE__}")
                    puts "User input @pcCmdNew='#{@pcCmdNew}'"
                end
                client.close                 # Disconnect from the client
            }
        end
        
    end
=end

    def runThreadForSavingSlotStateEvery10Mins()
        waitTime = Time.now
        waitTime += 60*10 # 60 seconds per minute x 10 minute
        saveStateOfBoard = Thread.new do
        	while true
                sleep(waitTime.to_f-Time.now.to_f)
                waitTime += 60*10
                if @samplerData.GetBbbMode() == SharedLib::InRunMode && @samplerData.GetAllStepsDone_YesNo() == SharedLib::No
                    saveBoardStateToHoldingTank()
                end
        	end
        end
    end
    
    def setAllStepsDone_YesNo(allStepsDone_YesNoParam,calledFrom)
        #if allStepsDone_YesNoParam == SharedLib::Yes
        #    puts caller # Kernel#caller returns an array of strings
        #    SharedLib.pause "Bingo! caled from #{calledFrom}","#{__LINE__}-#{__FILE__}"
        #end
        @boardData[SharedLib::AllStepsDone_YesNo] = allStepsDone_YesNoParam
        @samplerData.SetAllStepsDone_YesNo(allStepsDone_YesNoParam,"#{__LINE__}-#{__FILE__}")
    end    

    def loadConfigurationFromHoldingTank(uart1)
        begin
			fileRead = ""
			File.open(HoldingTankFilename, "r") do |f|
				f.each_line do |line|
					fileRead += line
				end
			end
			# puts fileRead
			setBoardData(JSON.parse(fileRead),uart1)
			# @boardData[SharedLib::AllStepsDone_YesNo] = SharedLib::No
			
			# puts "Checking content of getConfiguration() function"
			# puts "getConfiguration().nil?='#{getConfiguration().nil?}'"
			# PP.pp(getConfiguration())
			# pause "Holding tank content was loaded.","#{__LINE__}-#{__FILE__}"
			rescue Exception => e  
                puts "e.message=#{e.message }"
                puts "e.backtrace.inspect=#{e.backtrace.inspect}" 
        		SharedLib.bbbLog("There's no data in the holding tank.  New machine starting up. #{__LINE__}-#{__FILE__}")
        		setBoardData(Hash.new,uart1)
        		setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
	    end
    end
    
    def getMuxValue(aMuxParam)
        a=0
        @gPIO2.setGPIO2(GPIO2::ANA_MEAS4_SEL_xD, aMuxParam)
        while a<5
            readValue = @pAinMux.read
            a += 1
        end
        return @pAinMux.read
    end
    
    def pollAdcInput()
        # puts "E #{__LINE__}-#{__FILE__}"
        if @initpollAdcInputFunc
            # puts "f #{__LINE__}-#{__FILE__}"
            pAin = AINPin.new(:P9_39)
            # puts "g #{__LINE__}-#{__FILE__}"
            # puts "pAin.read=#{pAin.read}"
            # puts "g.1 #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::SLOTP5V,pAin.read,@multiplier)
            # puts "h #{__LINE__}-#{__FILE__}"

            pAin = AINPin.new(:P9_40)
            # puts "i #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::SLOTP3V3,pAin.read,@multiplier)
            # puts "j #{__LINE__}-#{__FILE__}"

            pAin = AINPin.new(:P9_37)
            # puts "k #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::SLOTP1V8,pAin.read,@multiplier)
            # puts "l #{__LINE__}-#{__FILE__}"

            pAin = AINPin.new(:P9_38)
            # puts "m #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::SlotTemp1,pAin.read,@multiplier)
            # puts "n #{__LINE__}-#{__FILE__}"

            pAin = AINPin.new(:P9_36)
            # puts "o #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::CALREF,pAin.read,@multiplier)
            # puts "p #{__LINE__}-#{__FILE__}"

            pAin = AINPin.new(:P9_35)
            # puts "q #{__LINE__}-#{__FILE__}"
            @samplerData.SetData(SharedLib::AdcInput,SharedLib::SlotTemp2,pAin.read,@multiplier)
            # puts "r #{__LINE__}-#{__FILE__}"
        else
            # The code is not initialized to run this function
            puts "The code is not initialized to run this function - #{__LINE__}-#{__FILE__}"
            exit
        end
    end
    
    def pollMuxValues()
        if @initMuxValueFunc
            aMux = 0
            @pAinMux = AINPin.new(:P9_33)
            while aMux<48
                retval = getMuxValue(aMux)
                if aMux == 2
                    useIndex = 4
                elsif aMux == 3
                    useIndex = 5
                elsif aMux == 4
                    useIndex = 2
                elsif aMux == 5
                    useIndex = 3
                elsif aMux == 10
                    useIndex = 12
                elsif aMux == 11
                    useIndex = 13
                elsif aMux == 12
                    useIndex = 10
                elsif aMux == 13
                    useIndex = 11
                elsif aMux == 18
                    useIndex = 20
                elsif aMux == 19
                    useIndex = 21
                elsif aMux == 20
                    useIndex = 18
                elsif aMux == 21
                    useIndex = 19
                else
                    useIndex = aMux
                end
                @samplerData.SetData(SharedLib::MuxData,useIndex,retval,@multiplier)
                # puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) "
                aMux += 1
                # sleep(1)
            end
        else
            # The code is not initialized to run this function
            puts "The code is not initialized to run this function - #{__LINE__}-#{__FILE__}"
            exit
        end
    end
    MeasErr = 1.01    	
    def initMuxValueFunc()
    	@initMuxValueFunc = true
    	@multiplier[SharedLib::IDUT1] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT2] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT3] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT4] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT5] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT6] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT7] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT8] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT9] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT10] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT11] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT12] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT13] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT14] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT15] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT16] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT17] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT18] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT19] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT20] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT21] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT22] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT23] = 20.0*0.65334305
    	@multiplier[SharedLib::IDUT24] = 20.0*0.65334305
    	@multiplier[SharedLib::IPS6] = 2.0*MeasErr
    	@multiplier[SharedLib::IPS8] = 5.0*MeasErr
    	@multiplier[SharedLib::IPS9] = 5.0*MeasErr
    	@multiplier[SharedLib::IPS10] = 5.0*MeasErr
    	@multiplier[SharedLib::SPARE] = 5.0*MeasErr
    	@multiplier[SharedLib::IP5V] = 5.0*MeasErr
    	@multiplier[SharedLib::IP12V] = 10.0*MeasErr
    	@multiplier[SharedLib::IP24V] = 10.0*MeasErr*3
    	@multiplier[SharedLib::VPS0] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS1] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS2] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS3] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS4] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS5] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS6] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS7] = 2.300*MeasErr
    	@multiplier[SharedLib::VPS8] = 4.010*MeasErr
    	@multiplier[SharedLib::VPS9] = 4.010*MeasErr
    	@multiplier[SharedLib::VPS10] = 4.010*MeasErr
    	@multiplier[SharedLib::BIBP5V] = 4.010*MeasErr
    	@multiplier[SharedLib::BIBN5V] = 4.010*MeasErr
    	@multiplier[SharedLib::BIBP12V] = 9.660*MeasErr
    	@multiplier[SharedLib::P12V] = 9.660*MeasErr
    	@multiplier[SharedLib::P24V] = 20.100*MeasErr
    end
    
    def initpollAdcInputFunc()
    	@initpollAdcInputFunc = true
    	@multiplier[SharedLib::SLOTP5V] = 4.01*MeasErr
    	@multiplier[SharedLib::SLOTP3V3] = 2.3*MeasErr
    	@multiplier[SharedLib::SLOTP1V8] = 2.3*MeasErr
    	@multiplier[SharedLib::SlotTemp1] = 100.0*MeasErr
    	@multiplier[SharedLib::CALREF] = 2.3*MeasErr
    	@multiplier[SharedLib::SlotTemp2] = 100.0*MeasErr
    end

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
    
    def readInEthernetScheme
        # Read in the EthernetScheme.csv file
		ethernetScheme = Array.new
		@ethernetScheme = Hash.new
		File.open("../BBB_configuration files/ethernet scheme setup.csv", "r") do |f|
			f.each_line do |line|
				ethernetScheme.push(line)
			end
		end
		SharedLib.bbbLog("No value checking in code within this section, ie, if column value is a valid number, or column name is not recognize. #{__LINE__}-#{__FILE__}")
		ct = 0
		while ct < ethernetScheme.length do
            if ct >= 1
		        columns = ethernetScheme[ct].split(",")
                @ethernetScheme[columns[0]] = columns[1]
            end
            ct += 1
        end
        # PP.pp(@ethernetScheme)
        # SharedLib.pause "Checking @ethernetScheme value","#{__LINE__}-#{__FILE__}"
    end
    
    def readInBbbDefaultsFile
        # Read the BBB-Defaults file.csv file
		bbbDefaultFile = Array.new
		@bbbDefaultFile = Hash.new
		File.open("../BBB_configuration files/board default setup.csv", "r") do |f|
			f.each_line do |line|
				bbbDefaultFile.push(line)
			end
		end
		SharedLib.bbbLog("No value checking in code within this section, ie, if column value is a valid number, or column name is not recognize. #{__LINE__}-#{__FILE__}")
		ct = 0
		while ct < bbbDefaultFile.length do
		    if ct >= 2
		        columns = bbbDefaultFile[ct].split(",")
                name = columns[NameCol]
                if @bbbDefaultFile[name].nil?
                    @bbbDefaultFile[name] = Hash.new
                end
                @bbbDefaultFile[name][NomSetCol] = columns[NomSetCol]
                @bbbDefaultFile[name][TripMinCol] = columns[TripMinCol]
                @bbbDefaultFile[name][TripMaxCol] = columns[TripMaxCol]
                @bbbDefaultFile[name][FlagTolPCol] = columns[FlagTolPCol]
                @bbbDefaultFile[name][FlagTolNCol] = columns[FlagTolNCol]
                @bbbDefaultFile[name][EnableBitCol] = columns[EnableBitCol]
                @bbbDefaultFile[name][IdleStateCol] = columns[IdleStateCol]
                @bbbDefaultFile[name][LoadStateCol] = columns[LoadStateCol]
                @bbbDefaultFile[name][StartStateCol] = columns[StartStateCol]
                @bbbDefaultFile[name][RunStateCol] = columns[RunStateCol]
                @bbbDefaultFile[name][StopStateCol] = columns[StopStateCol]
                @bbbDefaultFile[name][ClearStateCol] = columns[ClearStateCol]
                @bbbDefaultFile[name][LocationCol] = columns[LocationCol]
		    end
                
            ct += 1
		end
    end
    
    def setTcuToStopMode()
        bitToUse = GPIO2::X9_ETS7|GPIO2::X9_ETS6|GPIO2::X9_ETS5|GPIO2::X9_ETS4|GPIO2::X9_ETS3|GPIO2::X9_ETS2|GPIO2::X9_ETS1|GPIO2::X9_ETS0
        @gPIO2.etsEna1SetOff(bitToUse)
        @gPIO2.etsEna2SetOff(bitToUse)
        @gPIO2.etsEna3SetOff(bitToUse)
    end

=begin    
    def turnOffDuts(tcusToSkipParam)
        SharedLib.bbbLog "Turning on controllers.  #{__LINE__}-#{__FILE__}"
        ct = 0
        while ct<24 do
            if tcusToSkipParam[ct].nil? == true
                bitToUse = etsEnaBit(ct)
                if 0<=ct && ct <=7  
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna1Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna1SetOff(bitToUse)
                elsif 8<=ct && ct <=15
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna2Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna2SetOff(bitToUse)
                elsif 16<=ct && ct <=23
                    # SharedLib.bbbLog "Turning on controller '#{ct}' (zero base),  @gPIO2.etsEna3Set('#{bitToUse}').  #{__LINE__}-#{__FILE__}"
                    @gPIO2.etsEna3SetOff(bitToUse)
                end
            end
            ct += 1
        end
    end
=end

    def limboCheck(stepNum,uart1)
        configName = @samplerData.GetConfigurationFileName()
        if ((@boardData[SharedLib::AllStepsDone_YesNo] == SharedLib::No ||
             @boardData[SharedLib::AllStepsDone_YesNo] == SharedLib::Yes ) == false) ||
             (configName.nil? == false && configName.length>0 && (stepNum.nil? || (stepNum.nil? ==false && stepNum.length==0)) && @boardData[SharedLib::AllStepsDone_YesNo] == SharedLib::No)
            loadConfigurationFromHoldingTank(uart1)
            setBoardStateForCurrentStep(uart1)
            if @stepToWorkOn.nil?
                setAllStepsDone_YesNo(SharedLib::Yes,"#{__LINE__}-#{__FILE__}") # Set it to run, and it'll set it up by itself.
            else
                setAllStepsDone_YesNo(SharedLib::No,"#{__LINE__}-#{__FILE__}") # Set it to run, and it'll set it up by itself.
            end
        end
        if (@samplerData.GetBbbMode() == SharedLib::InRunMode || @samplerData.GetBbbMode() == SharedLib::InStopMode) == false  
            #
            # We're in limbo for some reason
            #
            puts "We're in limbo @samplerData.GetBbbMode()='#{@samplerData.GetBbbMode()}' #{__LINE__}-#{__FILE__}"
            loadConfigurationFromHoldingTank(uart1)

		    case @lastPcCmd
		    when SharedLib::RunFromPc
    		    setToMode(SharedLib::InRunMode,"#{__LINE__}-#{__FILE__}")
		    when SharedLib::StopFromPc
		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
		    when SharedLib::ClearConfigFromPc
		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
		    when SharedLib::LoadConfigFromPc
		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
    		else
		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
    		end
            setBoardStateForCurrentStep(uart1)
        end
    end
    
    
    def makeItFitMeas(itemToPrint,column,fitToCol)
        itemToPrint = itemToPrint.to_s
        while itemToPrint.length < column
            itemToPrint += "0"
        end
        if itemToPrint.length > column
            itemToPrint = itemToPrint[0..(column-1)]
        end
        
        if itemToPrint.length > fitToCol.length
            itemToPrint = itemToPrint[0..(fitToCol.length-1)]
        end
        
        while itemToPrint.length < fitToCol.length
            itemToPrint = " "+itemToPrint
        end
        return itemToPrint
    end

    def makeItFit(itemToPrint,column)
        itemToPrint = itemToPrint.to_s
        while itemToPrint.length < column.length
            itemToPrint = " "+itemToPrint
        end
        if itemToPrint.length > column.length
            itemToPrint = itemToPrint[0..(column.length-1)]
        end
        return itemToPrint
    end

    def sendToLogger(tbs)
        slotInfo = Hash.new()
        slotInfo[SharedLib::DataLog] = tbs
        slotInfo[SharedLib::SlotOwner] = @samplerData.GetSlotOwner# GetSlotIpAddress()
        slotInfo[SharedLib::ConfigurationFileName] = @samplerData.GetConfigurationFileName()
        slotInfo[SharedLib::ConfigDateUpload] = @samplerData.GetConfigDateUpload()
        slotInfoJson = slotInfo.to_json
        SendSampledTcuToPCLib::sendLoggerPart(slotInfoJson)
    end
    
    def turnOnHeaters
        @heatersTurnedOff = false
        # @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
        @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
    end
    
    def turnOffHeaters
        @heatersTurnedOff = true
        # @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
        @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
    end
    
    def fanCtrl(pwmParam, fanParam)
        # puts "fanCtrl pwm='#{pwmParam}', fan='#{fanParam}' [#{__LINE__}-#{__FILE__}]"
        if @lastPwmParam != pwmParam
            @lastPwmParam = pwmParam # So it won't keep calling the function
            @gPIO2.slotFanPulseWidthModulator(pwmParam)
        end
        
        if @lastFanParam != fanParam
            @lastFanParam = fanParam # So it won't keep calling the function
            case fanParam
            when 0
                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN1+GPIO2::X4_FAN2)
            when 1
                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN1+GPIO2::X4_FAN2)
                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN1)
            when 2
                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN1+GPIO2::X4_FAN2)
                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN2)
            when 3
                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_FAN1+GPIO2::X4_FAN2)
            else
                @samplerData.ReportError("fanParam='#{fanParam}' is wrong.  Expect value 0-3. #{__LINE__}-#{__FILE__}",Time.new)
            end
        end
    end

    def getVoltsCurrentPsAvg(psName,voltParam,currentParam)
        if @logRptAvg.nil?
            @logRptAvg = Hash.new
        end
        
        if @logRptAvg[psName].nil?
            @logRptAvg[psName] = Hash.new
        end
        
        if @logRptAvg[psName]["V"].nil?
            @logRptAvg[psName]["V"] = 0
        end
        @logRptAvg[psName]["V"] += voltParam
        
        if @logRptAvg[psName]["I"].nil?
            @logRptAvg[psName]["I"] = 0
        end
        @logRptAvg[psName]["I"] += currentParam.to_f
    end

    def doTheAveragingOfMesurements()
        @logRptAvgCt += 1
        dutCt = 0
        muxData = @samplerData.GetDataMuxData("#{__LINE__}-#{__FILE__}")
        adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
        eiPs = @samplerData.GetDataEips()
		while dutCt<24
			dutIndex = "Dut#{dutCt}"
			if @tcuData.nil? == false && @tcuData["#{dutCt}"].nil? == false 
                splitted = @tcuData["#{dutCt}"].split(',')
                if @logRptAvg.nil?
                    @logRptAvg = Hash.new
                end
                
                if @logRptAvg["#{dutCt}"].nil?
                    @logRptAvg["#{dutCt}"] = Hash.new
                end
                
                # The DUT status
                if @logRptAvg["#{dutCt}"]["status"].nil?
                    @logRptAvg["#{dutCt}"]["status"] = Hash.new
                end
                
                if @logRptAvg["#{dutCt}"]["status"][splitted[5]].nil?
                    @logRptAvg["#{dutCt}"]["status"][splitted[5]] = 0
                end
                @logRptAvg["#{dutCt}"]["status"][splitted[5]] += 1
                
                # The DUT temperature
                if @logRptAvg["#{dutCt}"]["temperature"].nil?
                    @logRptAvg["#{dutCt}"]["temperature"] = 0
                end
                @logRptAvg["#{dutCt}"]["temperature"] += splitted[2].to_f
                
                # The DUT current
                if @logRptAvg["#{dutCt}"]["current"].nil?
                    @logRptAvg["#{dutCt}"]["current"] = 0
                end
                current = SharedLib.getCurrentDutDisplay(muxData,"#{dutCt}")
                if current != SharedLib::DashLines
                    @logRptAvg["#{dutCt}"]["current"] += current.to_f
                else
                    @logRptAvg["#{dutCt}"]["current"] = SharedLib::DashLines
                end
                
				pWMoutput = splitted[4]
				if splitted[3] == "1"
				    if @logRptAvg["#{dutCt}"]["cool"].nil?
				        @logRptAvg["#{dutCt}"]["cool"] = 0
				        @logRptAvg["#{dutCt}"]["coolct"] = 0
				    end
				    @logRptAvg["#{dutCt}"]["cool"] += pWMoutput.to_f/255.0*100.0
				    @logRptAvg["#{dutCt}"]["coolct"] += 1
				else
				    if @logRptAvg["#{dutCt}"]["heat"].nil?
				        @logRptAvg["#{dutCt}"]["heat"] = 0
				        @logRptAvg["#{dutCt}"]["heatct"] = 0
				    end
				    @logRptAvg["#{dutCt}"]["heat"] += pWMoutput.to_f/255.0*100.0
				    @logRptAvg["#{dutCt}"]["heatct"] += 1
				end
				
				if @logRptAvg["#{dutCt}"]["controllerTemp"].nil?
				    @logRptAvg["#{dutCt}"]["controllerTemp"] = 0
				end
				@logRptAvg["#{dutCt}"]["controllerTemp"] += splitted[1].to_f
			end
			dutCt += 1
		end # of 'while dutCt<24'
        # Supply 0 <V set> <V measured> <I measured>
        getVoltsCurrentPsAvg("VPS0",@samplerData.getPsVolts(muxData,adcData,"32"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS0"))
        getVoltsCurrentPsAvg("VPS1",@samplerData.getPsVolts(muxData,adcData,"33"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS1"))
        getVoltsCurrentPsAvg("VPS2",@samplerData.getPsVolts(muxData,adcData,"34"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS2"))
        getVoltsCurrentPsAvg("VPS3",@samplerData.getPsVolts(muxData,adcData,"35"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS3"))
        getVoltsCurrentPsAvg("VPS4",@samplerData.getPsVolts(muxData,adcData,"36"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS4"))
        getVoltsCurrentPsAvg("VPS5",0,0)
        getVoltsCurrentPsAvg("VPS6",@samplerData.getPsVolts(muxData,adcData,"38"),@samplerData.getPsCurrent(muxData,eiPs,"24",nil))
        getVoltsCurrentPsAvg("VPS7",@samplerData.getPsVolts(muxData,adcData,"39"),@samplerData.getPsCurrent(muxData,eiPs,nil,"PS7"))
        getVoltsCurrentPsAvg("VPS8",@samplerData.getPsVolts(muxData,adcData,"40"),@samplerData.getPsCurrent(muxData,eiPs,"25",nil))
        getVoltsCurrentPsAvg("VPS9",@samplerData.getPsVolts(muxData,adcData,"41"),@samplerData.getPsCurrent(muxData,eiPs,"26",nil))
        getVoltsCurrentPsAvg("VPS10",@samplerData.getPsVolts(muxData,adcData,"42"),@samplerData.getPsCurrent(muxData,eiPs,"27",nil))

    	if @logRptAvg["#{Temp1}"].nil?
    	    @logRptAvg["#{Temp1}"] = 0
    	end
    	@logRptAvg["#{Temp1}"] += adcData[SharedLib::SlotTemp1.to_s].to_f/1000.0

    	if @logRptAvg["#{Temp2}"].nil?
    	    @logRptAvg["#{Temp2}"] = 0
    	end
    	@logRptAvg["#{Temp2}"] += adcData[SharedLib::SlotTemp2.to_s].to_f/1000.0

        # puts "-------------------------------------------"
        # puts "@logRptAvgCt=#{@logRptAvgCt}"
        # PP.pp(@logRptAvg)
    end

    def getSystemStateAvgForLogging()
        # mins =  ((@samplerData.GetStepTimeLeft())/60.0).to_i
        # secs =  (@samplerData.GetStepTimeLeft()-mins*60.0).to_i
        tbs = ""
        # tbs += "Log Time Left: #{SharedLib::makeTime2colon2Format(mins,secs)} (mm:ss)\n"
        tbs += "Log Time: #{Time.new.inspect}\n"
        tbs += "#{DutNum}|#{DutStatus}|#{DutTemp}|#{DutCurrent}|#{DutHeatDuty}|#{DutCoolDuty}|#{DutControllerTemp}|\n"
        dutCt = 0
        # tbs += "eiPs=#{eiPs}\n"
		while dutCt<24
			dutIndex = "Dut#{dutCt}"
			ct = 0
			
			if @logRptAvg.nil? == false && @logRptAvg["#{dutCt}"].nil? == false
			    @logRptAvg["#{dutCt}"]["status"].each do |key, data|
    			    if ct == 0
            			if @tcuData.nil? == false && @tcuData["#{dutCt}"].nil? == false 
                            splitted = @tcuData["#{dutCt}"].split(',')
                            tbs += "#{makeItFit(dutIndex,DutNum)}|"
                            tbs += "#{makeItFit("#{key}[#{data}/#{@logRptAvgCt}]",DutStatus)}|"
                            tbs += "#{makeItFit(@logRptAvg["#{dutCt}"]["temperature"]/@logRptAvgCt,DutTemp)}|"
                            tbs += "#{makeItFitMeas(@logRptAvg["#{dutCt}"]["current"]/@logRptAvgCt,5,DutCurrent)}|"
                            if @logRptAvg["#{dutCt}"]["cool"].nil?
                				coolDuty = 0
                            else
                				coolDuty = SharedLib::make5point2Format(@logRptAvg["#{dutCt}"]["cool"]/@logRptAvg["#{dutCt}"]["coolct"]/255.0*100.0)
                            end

                            if @logRptAvg["#{dutCt}"]["heat"].nil?
                				heatDuty = 0
                            else
                				heatDuty = SharedLib::make5point2Format(@logRptAvg["#{dutCt}"]["heat"]/@logRptAvg["#{dutCt}"]["heatct"]/255.0*100.0)
                            end
                            tbs += "#{makeItFit(heatDuty,DutHeatDuty)}|"
                            tbs += "#{makeItFit(coolDuty,DutCoolDuty)}|"
                            tbs += "#{makeItFitMeas(@logRptAvg["#{dutCt}"]["controllerTemp"]/@logRptAvgCt,5,DutControllerTemp)}|\n"
            			end
            		else
            			if @tcuData.nil? == false && @tcuData["#{dutCt}"].nil? == false 
                            splitted = @tcuData["#{dutCt}"].split(',')
                            tbs += "#{makeItFit(" ",DutNum)}|"
                            tbs += "#{makeItFit("#{key}[#{data}/#{@logRptAvgCt}]",DutStatus)}|"
                            tbs += "#{makeItFit(" ",DutTemp)}|"
                            tbs += "#{makeItFit(" ",DutCurrent)}|"
                            tbs += "#{makeItFit(" ",DutHeatDuty)}|"
                            tbs += "#{makeItFit(" ",DutCoolDuty)}|"
                            tbs += "#{makeItFit(" ",DutControllerTemp)}|\n"
            			end
    			    end
                    ct += 1
                end
			end
    		dutCt += 1
		end # of 'while dutCt<24'
        # Supply 0 <V set> <V measured> <I measured>
        tbs += "#{PSNameLogger}|#{VMeas}|#{IMeas}\n"
        tbs += "#{makeItFit("VPS0",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS0"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS0"]["I"]/@logRptAvgCt,5,IMeas)}\n"
        
        

        tbs += "#{makeItFit("VPS1",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS1"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS1"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS2",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS2"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS2"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS3",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS3"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS3"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS4",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS4"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS4"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS5",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS5"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS5"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS6",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS6"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS6"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS7",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS7"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS7"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS8",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS8"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS8"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS9",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS9"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS9"]["I"]/@logRptAvgCt,5,IMeas)}\n"

        tbs += "#{makeItFit("VPS10",PSNameLogger)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS10"]["V"]/@logRptAvgCt,5,VMeas)}|"
        tbs += "#{makeItFitMeas(@logRptAvg["VPS10"]["I"]/@logRptAvgCt,5,IMeas)}\n"
        tbs += "#{Temp1}|#{Temp2}\n"

        tbs += "#{makeItFitMeas((@logRptAvg["#{Temp1}"]/@logRptAvgCt).round(3),6,Temp1)}|"
        tbs += "#{makeItFitMeas((@logRptAvg["#{Temp2}"]/@logRptAvgCt).round(3),6,Temp2)}\n"
        sendToLogger(tbs)
    end

    def logSystemStateSnapShot(strParam, timeParam)
        tbs = "#{timeParam.inspect} - #{strParam}"
        if @isOkToLog
            mins =  (@samplerData.GetStepTimeLeft()/60.0).to_i
            secs =  (@samplerData.GetStepTimeLeft()-mins*60.0).to_i
            tbs += "Log Time Left: #{SharedLib.makeTime2colon2Format(mins,secs)} (mm:ss)\n"
            tbs += "#{DutNum}|#{DutStatus}|#{DutTemp}|#{DutCurrent}|#{DutHeatDuty}|#{DutCoolDuty}|#{DutControllerTemp}\n"
            dutCt = 0
            muxData = @samplerData.GetDataMuxData("#{__LINE__}-#{__FILE__}")
            adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
            eiPs = @samplerData.GetDataEips()
            # tbs += "eiPs=#{eiPs}\n"
    		while dutCt<24
    			dutIndex = "Dut#{dutCt}"
    			if @tcuData.nil? == false && @tcuData["#{dutCt}"].nil? == false 
                    splitted = @tcuData["#{dutCt}"].split(',')
                    tbs += "#{makeItFit(dutIndex,DutNum)}|"
                    tbs += "#{makeItFit(splitted[5],DutStatus)}|"
    				temperature = SharedLib::make5point2Format(splitted[2])
                    tbs += "#{makeItFit(temperature,DutTemp)}|"
                    tbs += "#{makeItFit(SharedLib.getCurrentDutDisplay(muxData,"#{dutCt}"),DutCurrent)}|"
    				pWMoutput = splitted[4]
    				
                    coolDuty = 0
    				heatDuty = 0
    				
    				if splitted[3] == "1"
                        coolDuty = SharedLib::make5point2Format(pWMoutput.to_f/255.0*100.0)
    				else
                        heatDuty = SharedLib::make5point2Format(pWMoutput.to_f/255.0*100.0)
    				end
                    tbs += "#{makeItFit(heatDuty,DutHeatDuty)}|"
                    tbs += "#{makeItFit(coolDuty,DutHeatDuty)}|"
    				controllerTemp = SharedLib::make5point2Format(splitted[1])
                    tbs += "#{makeItFitMeas(controllerTemp,6,DutControllerTemp)}\n"
    			end
    			dutCt += 1
    		end # of 'while dutCt<24'
            # Supply 0 <V set> <V measured> <I measured>
            tbs += "#{PSNameLogger}|#{VMeas}|#{IMeas}\n"
            tbs += "#{makeItFit("VPS0",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"32"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS0"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS1",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"33"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS1"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS2",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"34"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS2"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS3",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"35"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS3"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS4",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"36"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS4"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS5",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"37"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"IPS5"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS6",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"38"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"24",nil),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS7",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"39"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS7"),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS8",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"40"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"25",nil),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS9",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"41"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"26",nil),5,IMeas)}\n"
    
            tbs += "#{makeItFit("VPS10",PSNameLogger)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"42"),5,VMeas)}|"
            tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"27",nil),5,IMeas)}\n"
            tbs += "#{Temp1}|#{Temp2}\n"
    
            tbs += "#{makeItFitMeas((adcData[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(3),6,Temp1)}|"
            tbs += "#{makeItFitMeas((adcData[SharedLib::SlotTemp2.to_s].to_f/1000.0).round(3),6,Temp2)}\n"
        end
        sendToLogger(tbs)
    end

    # Set the values only one time
    FanPwm1 = 45
    FanPwm2 = 45
    FanPwm3 = 2*17 # 34
    FanPwm4 = 3*17 # 51
    FanPwm5 = 4*17 # 68
    FanPwm6 = 5*17 # 85
    FanPwm7 = 6*17 # 102
    FanPwm8 = 7*17 # 119
    FanPwm9 = 8*17 # 136
    FanPwm10 = 9*17 # 153
    FanPwm11 = 10*17 # 170
    FanPwm12 = 11*17 # 187
    FanPwm13 = 12*17 # 204
    FanPwm14 = 13*17 # 221
    FanPwm15 = 14*17 # 238
    FanPwm16 = 15*17 # 255

    # Set only once.
    CirculateAirPwm = FanPwm1
    FanValue = 3

    Alarming = 5

    def backFansHandler
        if @tempSetPoint.nil? == false && @samplerData.GetBbbMode() == SharedLib::InRunMode
            adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
            temp1Param = (adcData[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(4)
            deltaTemp = (temp1Param-@tempSetPoint).round(4)
            print "AmbientTemp(#{temp1Param})-TempSetPoint(#{@tempSetPoint})='#{deltaTemp}' [#{__LINE__}-#{__FILE__}] "
            if @samplerData.GetConfigurationFileName().length>0
                if deltaTemp < -25.0
                    fanCtrl(FanPwm1, FanValue)
                elsif -25.0 <= deltaTemp && deltaTemp < -20.0
                    fanCtrl(FanPwm2, FanValue)
                elsif -20.0 <= deltaTemp && deltaTemp < -15.0
                    fanCtrl(FanPwm3, FanValue)
                elsif -15.0 <= deltaTemp && deltaTemp < -10.0
                    fanCtrl(FanPwm4, FanValue)
                elsif -10.0 <= deltaTemp && deltaTemp < -5.0
                    fanCtrl(FanPwm5, FanValue)
                elsif -5.0 <= deltaTemp && deltaTemp < 0.0
                    fanCtrl(FanPwm6, FanValue)
                elsif 0.0 <= deltaTemp && deltaTemp < 5.0
                    fanCtrl(FanPwm7, FanValue)
                elsif 5.0 <= deltaTemp && deltaTemp < 10.0
                    fanCtrl(FanPwm8, FanValue)
                elsif 10.0 <= deltaTemp && deltaTemp < 15.0
                    fanCtrl(FanPwm9, FanValue)
                elsif 15.0 <= deltaTemp && deltaTemp < 20.0
                    fanCtrl(FanPwm10, FanValue)
                elsif 20.0 <= deltaTemp && deltaTemp < 25.0
                    fanCtrl(FanPwm11, FanValue)
                elsif 25.0 <= deltaTemp && deltaTemp < 30.0
                    fanCtrl(FanPwm12, FanValue)
                elsif 30.0 <= deltaTemp && deltaTemp < 35.0
                    fanCtrl(FanPwm13, FanValue)
                elsif 35.0 <= deltaTemp && deltaTemp < 40.0
                    fanCtrl(FanPwm14, FanValue)
                elsif 40.0 <= deltaTemp && deltaTemp < 45.0
                    fanCtrl(FanPwm15, FanValue)
                elsif 45.0 <= deltaTemp
                    fanCtrl(255, FanValue)
                end
            end
        else
            # There's nothing loaded
            fanCtrl(CirculateAirPwm, FanValue)
        end
    end
    
    def setToAlarmMode()
        @lastSettings = Alarming
        @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
        if @setupAtHome
            @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDRED+GPIO2::X4_BLINK)
        else
            @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_BLINK)
        end
    end

    def is2ndFaultBase(key2,unit,tripMin,actualValue,tripMax,tbsParam)  
        if @fault.nil?
            @fault = Hash.new
        end
        
        if @fault[key2].nil?
            @fault[key2] = 1
            tbs = tbsParam # tbs - to be sent
            timeOfError = Time.new
            @samplerData.ReportError(tbs,timeOfError)
            logSystemStateSnapShot(tbs,timeOfError)
            return false
        end
        
        if @fault[key2] >= 1
            return true
        else
            return false
        end
    end
    
    def is2ndFault(key2,unit,tripMin,actualValue,tripMax)        
        tbsParam = "Possible error - #{key2} out of bound trip points.  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} failed.\n" # tbs - to be sent
        return is2ndFaultBase(key2,unit,tripMin,actualValue,tripMax,tbsParam)
    end
    
    def is2ndFaultDut(key2,dutCt,unit,tripMin,actualValue,tripMax)        
        tbsParam = "Possible error - DUT##{dutCt} out of bound trip points.  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} failed.\n" # tbs - to be sent
        return is2ndFaultBase(key2,unit,tripMin,actualValue,tripMax,tbsParam)
    end

    def clearFault(key2)
        if @fault.nil?
            @fault = Hash.new
        end
        if @fault[key2].nil? == false
            @fault[key2] = nil
        end
    end

    def testBadMeasForTripPts(key2,actualValue, fromParam)
        puts "testBadMeasForTripPts for '#{key2}'. [called from #{fromParam}] #{__LINE__}-#{__FILE__}"

        if @testBadMeasForTripPts.nil?
            @testBadMeasForTripPts = Hash.new
        end
        
        if @testBadMeasForTripPts[key2].nil?
            @testBadMeasForTripPts[key2] = key2
            puts "testBadMeasForTripPts for '#{key2}' returning fudged data. #{__LINE__}-#{__FILE__}"
            return 1000*actualValue
        else
            return actualValue
        end
    end

    def setDutErrorColorFlag(key2,ct,flag)
        setErrorColorFlagBase(key2)        
        
        if @boardData[SharedMemory::ErrorColor][key2][ct].nil?
            @boardData[SharedMemory::ErrorColor][key2][ct] = Hash.new
        end
        
        if @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::Latch].nil?
            @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::Latch] = flag
        elsif @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::Latch] < flag
            @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::Latch] = flag
        end

        if @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::CurrentState].nil?
            @boardData[SharedMemory::ErrorColor][key2][ct][SharedMemory::CurrentState] = flag
        end
        
        @samplerData.setErrorColor(@boardData[SharedMemory::ErrorColor])
    end

    def evaluatedDevices(pollIntervalInSeconds, pollingTime, uart1, twtimeleft)
        # puts "@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)=#{@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)}  #{__LINE__}-#{__FILE__}"
	    if @stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)>0
	        # We're still running.
	        
	        @tcuData = @samplerData.parseOutTcuData(@samplerData.GetDataTcu("#{__LINE__}-#{__FILE__}"))
            tempTolP="P Not Set"
            tempTolN="N Not Set"
	        # Check for the trip points.  How are we going to check them?
	        # First, display the trip points, then display the current values.
	        # Then compare the two values.  If trip points fail
	        @stepToWorkOn.each do |key, array|
                # puts "#{key}----- #{__LINE__}-#{__FILE__}"
                if key == "PsConfig"
                    adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
                    muxData = @samplerData.GetDataMuxData("#{__LINE__}-#{__FILE__}")
                    eiPs = @samplerData.GetDataEips()
                    tcu = @samplerData.GetDataTcu("#{__LINE__}-#{__FILE__}")
                    array.each do |key2, array2|
                        nomSet = array2["NomSet"].to_f
			            tripMin = array2["TripMin"].to_f
			            tripMax = array2["TripMax"].to_f
			            flagTolP = array2["FlagTolP"].to_f
			            flagTolN = array2["FlagTolN"].to_f

                        if (tripMin < tripMax) == false
                            hold = tripMin
                            tripMin = tripMax
                            tripMax = hold
                        end

			            if (flagTolP < flagTolN) == false
			                hold = flagTolP
			                flagTolP = flagTolN
			                flagTolN = hold
			            end
			            
			            # puts "key='#{key2}',nomSet = '#{nomSet}', tripMin = '#{tripMin}', tripMax = '#{tripMax}', flagTolP = '#{flagTolP}', flagTolN='#{flagTolN}'"
                        case key2
                        when "VPS0"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"32").to_f
                            if @setupAtHome
                                actualValue = 1.095
                            end
                            
                            # actualValue = testBadMeasForTripPts(key2,actualValue,"#{__LINE__}-#{__FILE__}")
                            
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax,flagTolP,flagTolN)
                                return
                            end
                       when "IPS0"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            # actualValue = testBadMeasForTripPts(key2,actualValue,"#{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS1"
                            # puts "PS1V = #{@samplerData.getPsVolts(muxData,adcData,"33")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"33").to_f
                            if @setupAtHome
                                actualValue = 0.9
                            end
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS1"
                            # puts "PS1I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,key2)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS2"
                            # puts "PS2V = #{@samplerData.getPsVolts(muxData,adcData,"34")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"34").to_f
                            if @setupAtHome
                                actualValue = 1.5
                            end
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS2"
                            # puts "PS2I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,key2)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS3"
			                # puts "key='#{key2}',nomSet = '#{nomSet}', tripMin = '#{tripMin}', tripMax = '#{tripMax}', flagTolP = '#{flagTolP}', flagTolN='#{flagTolN}'"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"35").to_f
                            if @setupAtHome
                                actualValue = 0.9
                            end
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS3"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            # puts "eiPs=#{eiPs} #{__LINE__}-#{__FILE__}"
                            # puts "key2=#{key2}, key2[1..-1]=#{key2[1..-1]} #{__LINE__}-#{__FILE__}"
                            # puts "actualValue=#{actualValue} #{__LINE__}-#{__FILE__}"
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS4"
                            # puts "PS4V = #{@samplerData.getPsVolts(muxData,adcData,"36")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"36").to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS4"
                            # puts "PS4I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,"IPS2")}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            # actualValue = testBadMeasForTripPts(key2,actualValue,"#{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS5"
                            # puts "PS5V = #{@samplerData.getPsVolts(muxData,adcData,"37")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"37").to_f
                            # actualValue = testBadMeasForTripPts(key2,actualValue,"#{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS5"
                            # puts "PS5I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,nil).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS6"
                            # puts "PS6V = #{@samplerData.getPsVolts(muxData,adcData,"38")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"38").to_f
                            if @setupAtHome
                                actualValue = 3.3
                            end
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS6"
                            # puts "PS6I = #{@samplerData.getPsCurrent(muxData,eiPs,"24",nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"24",nil).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS7"
                            # puts "PS7V = #{@samplerData.getPsVolts(muxData,adcData,"39")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"39").to_f
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if @setupAtHome
                                actualValue = 0.9
                            end
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS7"
                            # puts "PS7I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2[1..-1]).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS8"
                            # puts "PS8V = #{@samplerData.getPsVolts(muxData,adcData,"40")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"40").to_f
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if @setupAtHome
                                actualValue = 5.0
                            end
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS8"
                            # puts "PS8I = #{@samplerData.getPsCurrent(muxData,eiPs,"25",nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"25",nil).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS9"
                            # puts "PS9V = #{@samplerData.getPsVolts(muxData,adcData,"41")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"41").to_f
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if @setupAtHome
                                actualValue = 2.1
                            end
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS9"
                            # puts "PS9I = #{@samplerData.getPsCurrent(muxData,eiPs,"26",nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"26",nil).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "VPS10"
                            # puts "PS10V = #{@samplerData.getPsVolts(muxData,adcData,"42")}"
                            actualValue = @samplerData.getPsVolts(muxData,adcData,"42").to_f
                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                            if @setupAtHome
                                actualValue = 2.5
                            end
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IPS10"
                            # puts "PS10I = #{@samplerData.getPsCurrent(muxData,eiPs,"27",nil)}"
                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"27",nil).to_f
                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                return
                            end
                        when "IDUT"
                            unit = "A"
                            ct = 0
                            while ct<24 do
                                if @tcusToSkip[ct].nil? == true
            						# puts "dutI#{ct} = '#{SharedLib.getCurrentDutDisplay(muxData,"#{ct}")}'"
                                    actualValue = SharedLib.getCurrentDutDisplay(muxData,"#{ct}").to_f
                                    if (flagTolP <= actualValue && actualValue <= flagTolN) == false
                                        @samplerData.ReportError("NOTICE - IDUT#{ct} out of bound flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed.  .",Time.new)
                                        ct = 24 # break out of the loop.
                                        setDutErrorColorFlag(key2,ct,SharedMemory::OrangeFlag)

                                        # actualValue = testBadMeasForTripPts("#{key2}#{ct}",actualValue,"#{__LINE__}-#{__FILE__}")
                                        if (tripMin <= actualValue && actualValue <= tripMax) == false
                                            if is2ndFaultDut("#{key2}#{ct}",ct,unit,tripMin,actualValue,tripMax)
                                                setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
                                                setToAlarmMode()
                                                tbs = "ERROR - IDUT#{ct} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE."
                                                timeOfError = Time.new
                                                @samplerData.setStopMessage("Trip Point Error, Stopped.")
                                                setDutErrorColorFlag(key2,ct,SharedMemory::RedFlag)
                                                @samplerData.ReportError(tbs,timeOfError)
                                                logSystemStateSnapShot(tbs,timeOfError)
                                                # ct = 24 # break out of the loop.
                                                return
                                            end
                                        end

                                    else
                                        setDutErrorColorFlag(key2,ct,SharedMemory::GreenFlag)
                                        clearFault("#{key2}#{ct}")
                                    end
                                end
                                ct += 1
                            end
                        else
                            if @spsList.nil?
                                # Make the list a global var so it will not keep creating the list per loop.
                                @spsList =  ['SPS0','SPS1','SPS2','SPS3','SPS4','SPS5','SPS6','SPS7','SPS8','SPS9','SPS10']
                            end
                            
                            # Code don't seem to work.
                            if @spsList.include? key2 == false
                                @samplerData.ReportError("key='#{key2}' is not recognized. #{__LINE__}-#{__FILE__}",Time.new)
                            end
                        end                    			            
                    end
                elsif key == "TempConfig"
                    array.each do |key2, array2|
                        nomSet = array2["NomSet"]
			            tripMin = array2["TripMin"]
			            tripMax = array2["TripMax"]
			            flagTolP = array2["FlagTolP"]
			            flagTolN = array2["FlagTolN"]
			            # puts "key='#{key2}',nomSet = '#{nomSet}', tripMin = '#{tripMin}', tripMax = '#{tripMax}', flagTolP = '#{flagTolP}', flagTolN='#{flagTolN}'"
                        case key2
                        when "TDUT"
                            if (tripMin < tripMax) == false
                                hold = tripMin
                                tripMin = tripMax
                                tripMax = hold
                            end

    			            if (flagTolP < flagTolN) == false
    			                hold = flagTolP
    			                flagTolP = flagTolN
    			                flagTolN = hold
    			            end
                        
                            dutCt = 0
                            @totDutTempReached = 0
                            @totDutsAvailable = 0
                            tempTolP = flagTolP
                            tempTolN = flagTolN
            				while dutCt<24 
            					if @tcuData.nil? == false && @tcuData["#{dutCt}"].nil? == false 
					                splitted = @tcuData["#{dutCt}"].split(',')
            						temperature = SharedLib::make5point2Format(splitted[2]).to_f
                                    # puts "dut##{dutCt} flagTolP='#{flagTolP}' <= temp='#{temperature}' <= #{flagTolN} : '#{flagTolP<=temperature && temperature<=flagTolN}'"
                				    if flagTolP<=temperature && temperature<=flagTolN
                				        if @dutTempTolReached[dutCt].nil?
                    				        @dutTempTolReached[dutCt] = true
                				        end
                				    end
                				    
                				    if @dutTempTolReached[dutCt] == true
                				        @totDutTempReached += 1
                				    end
                				    @totDutsAvailable += 1
                                end
            				    dutCt += 1
            				end
            				
            				if @allDutTempTolReached == false && @stepToWorkOn[CalculatedTempWait]-(Time.now.to_f-@waitTempStartTime)<0
            				    @totDutTempReached = @totDutsAvailable
            				end

            				if @totDutTempReached == @totDutsAvailable
            				    if @allDutTempTolReached == false 
            				        @allDutTempTolReached = true
            				        @samplerData.setWaitTempMsg("")
            				        @samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
            				        setTimeOfRun()
            				    end
            				end
            				
        				    if @allDutTempTolReached == false 
        				        setTimeOfRun() # So the countdown will never take place.
        				    end
                            # puts "@totDutTempReached='#{@totDutTempReached}'/'#{@totDutsAvailable}' @allDutTempTolReached = '#{@allDutTempTolReached}'"
            				
                            if @allDutTempTolReached
                                if @tcuData.nil? == false
                                    dutCt = 0
                                    unit = "C"
                        			while dutCt<24
                        			    if @tcuData["#{dutCt}"].nil? == false 
                        	                splitted = @tcuData["#{dutCt}"].split(',')
                        					actualValue = SharedLib::make5point2Format(splitted[2]).to_f
                        					# puts "DUT##{dutCt} temp='#{actualValue}' flagTolN='#{flagTolN}' flagTolP='#{flagTolP}' tripMin='#{tripMin}' tripMax='#{tripMax}'"
                                            if (flagTolP <= actualValue && actualValue <= flagTolN) == false
                                                puts "NOTICE - DUT##{dutCt} out of bound within flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed.  ."
                                                @samplerData.ReportError("NOTICE - DUT##{dutCt} out of bound flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed.  .",Time.new)
                                                setDutErrorColorFlag(key2,dutCt,SharedMemory::OrangeFlag)

                                                # actualValue = testBadMeasForTripPts("#{key2}#{dutCt}",actualValue,"#{__LINE__}-#{__FILE__}")
    
                                                if (tripMin <= actualValue && actualValue <= tripMax) == false
                                                    if is2ndFaultDut("#{key2}#{dutCt}",dutCt,unit,tripMin,actualValue,tripMax)
                                                        # puts("ERROR - DUT##{dutCt} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE.")
                                                        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
    
                                                        # Turn on red light and buzzer and make it blink due to shutdown
                                                        setToAlarmMode()
                                                        tbs = "ERROR - DUT##{dutCt} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE." # tbs - to be sent
                                                        # dutCt = 24 
                                                        timeOfError = Time.new
                                                        @samplerData.ReportError(tbs,timeOfError)
                                                        @samplerData.setStopMessage("Trip Point Error, Stopped.")
                                                        setDutErrorColorFlag(key2,dutCt,SharedMemory::RedFlag)
                                                        logSystemStateSnapShot(tbs,timeOfError)
                                                        return
                                                    end
                                                end
                                            else
                                                setDutErrorColorFlag(key2,dutCt,SharedMemory::GreenFlag)
                                                clearFault("#{key2}#{dutCt}")
                                            end
                        			    end
                                        dutCt += 1
                    				end
                                end
                            end
                        else
                            if @tempStuff.nil?
                                # Make the list a global var so it will not keep creating the list per loop.
                                @tempStuff = ['TIMERRUFP','TIMERRDFP','H','C','P','I','D']
                            end
                            
                            if @tempStuff.include? key2 == false
                                @samplerData.ReportError("key='#{key2}' is not recognized. #{__LINE__}-#{__FILE__}",Time.new)
                            end
                        end                    			            
                    end
                else
                    if @otherStuff.nil?
                        # Make the list a global var so it will not keep creating the list per loop.
                        @otherStuff = ['xStdep Num','Step Time','TEMP WAIT','Alarm Wait','Auto Restart','Stop on Tolerance','StepTimeLeft','TIMERRUFP','TIMERRDFP']
                    end
                    
                    if @otherStuff.include? key == false
                        @samplerData.ReportError("key='#{key}' is not recognized. #{__LINE__}-#{__FILE__}",Time.new)
                    end
                end
            end
            
            # We're in run mode.
            if pollIntervalInSeconds == pollingTime
                # The board started processing.
                pollIntervalInSeconds = @loggingTime
            end
            
            if @isOkToLog && @allDutTempTolReached
                doTheAveragingOfMesurements()
                if @timeOfLog.to_i <= Time.now.to_i
                    @timeOfLog += pollIntervalInSeconds
                    getSystemStateAvgForLogging()
                    @logRptAvgCt = 0
                    @logRptAvg = nil
                end
                
                @samplerData.SetStepTimeLeft(@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun()))
            else
                @samplerData.setWaitTempMsg("#{tempTolP}C/#{tempTolN}C, +#{@totDutTempReached}/#{@totDutsAvailable} duts, -#{twtimeleft} sec")
                #@totDutTempReached == @totDutsAvailable
            end
	    else
	        # We're done running.
            @dutTempTolReached = Hash.new
            @allDutTempTolReached = false
            
	        # Step just finished.
            # We're in polling mode.
            if pollIntervalInSeconds == @loggingTime
                pollIntervalInSeconds = pollingTime
            end
            
            setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
            setBoardStateForCurrentStep(uart1)
            # SharedLib.pause "Finished step. @stepToWorkOn.nil?=#{@stepToWorkOn.nil?}","#{__LINE__}-#{__FILE__}"
            if @stepToWorkOn.nil? == false
                # There's more step to process
    		    setToMode(SharedLib::InRunMode,"#{__LINE__}-#{__FILE__}")
            else
                @boardData[SharedLib::AllStepsCompletedAt] = Time.new.to_i
                setAllStepsDone_YesNo(SharedLib::Yes,"#{__LINE__}-#{__FILE__}")

                # Done processing all steps listed in configuration.step file
                saveBoardStateToHoldingTank()
                
                # We're done processing all the steps.
            end
        end
    end
    
    def runAwayTempHandler() # Need to verify this code.
        # Handle run away temperatures
        if @samplerData.GetBbbMode() != SharedLib::InRunMode && @heatersTurnedOff == false
            if @tcuData.nil? == false
                dutCt = 0
                unit = "C"
    			while dutCt<24
    			    if @tcuData["#{dutCt}"].nil? == false 
    	                splitted = @tcuData["#{dutCt}"].split(',')
    					actualValue = SharedLib::make5point2Format(splitted[2]).to_f
                        if (actualValue <= @dutTempTripMax) == false
                            if is2ndFaultDut("OverTemp#{dutCt}",dutCt,unit,tripMin,actualValue,tripMax)
                                # puts("ERROR - DUT##{dutCt} OVER TEMP ERROR!  '#{actualValue}'#{unit} <= '#{@dutTempTripMax}'#{unit} FAILED.  ALREADY IN STOP MODE, SHUTTING DOWN HEATERS.")
                                turnOffHeaters()

                                # Turn on red light and buzzer and make it blink due to shutdown
                                setToAlarmMode()
                                @samplerData.setStopMessage("Trip Point Error, Stopped.")
                                setDutErrorColorFlag("TDUT",dutCt,SharedMemory::RedFlag)
                                @samplerData.ReportError("ERROR - DUT##{dutCt} OUT OF BOUND TRIP POINTS!  '#{@dutTempTripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{@dutTempTripMax}'#{unit} FAILED.  ALREADY IN STOP MODE, SHUTTING DOWN HEATERS.",Time.new)
                                return
                            end
                        else
                            clearFault("OverTemp#{dutCt}")
                        end
    			    end
                    dutCt += 1
    			end
            end
        end
    end
    
    def lightsAndBuzzerHandler(cfgName)
        # Handle the lights and buzzer
        if cfgName == "Yes"
            # We have a step config file loaded.
            # puts "EXT_INPUTS_x2=#{@gPIO2.getGPIO2(GPIO2::EXT_INPUTS_x2)} #{__LINE__}-#{__FILE__}"
            if @lastSettings != Alarming
                # There's a lot loaded.
                if @samplerData.GetBbbMode() == SharedLib::InRunMode
                    # The lot is running, set the green lights on
                    if @lastSettings != 1 
                        @lastSettings = 1 # To prevent from getting called again
                        @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
                        @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDGRN)
                    end
                elsif @samplerData.GetBbbMode() == SharedLib::InStopMode
                    if @samplerData.GetAllStepsDone_YesNo() == SharedLib::Yes
                        # Set the Green lights on and blink cuz it's done
                        if @lastSettings != 2
                            @lastSettings = 2 # To prevent from getting called again
                            @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
                            @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDGRN+GPIO2::X4_BLINK)
                        end
                    else
                        # Set the yellow lights on
                        if @lotStartedAlready
                            # Make the yellow lights to blink
                            if @lastSettings != 6
                                @lastSettings = 6 # To prevent from getting called again
                                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
                                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDYEL+GPIO2::X4_BLINK)
                            end
                        else
                            # Lot not started, yellow lights stay solid
                            if @lastSettings != 3
                                @lastSettings = 3 # To prevent from getting called again
                                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
                                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDYEL)
                            end
                        end
                    end
                end
            else
                # We're in an alarm state.
                # Check if the button was pressed.
                if SharedLib.getBits(@gPIO2.getGPIO2(GPIO2::EXT_INPUTS_x2))[-2] == "1"
                    # The button was pressed.  The idea is to silence the beeping noise for 5 mins.
                    @gPIO2.setGPIO2(GPIO2::EXT_INPUTS_x2,1) # Clear the pressed button.
                    
                    @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BUZR)
                    turnBuzzerOnAt = Time.now+5*60
                    buzzerBackOn = false
                end
                
                if buzzerBackOn == false && turnBuzzerOnAt <= Time.now
                    buzzerBackOn = true
                    @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BUZR)
                end
            end
        else
            # No lot loaded.
            # Set the yellow lights on
            if @lastSettings != 4
                @lastSettings = 4 # To prevent from getting called again
                @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_BLINK+GPIO2::X4_BUZR+GPIO2::X4_LEDRED+GPIO2::X4_LEDYEL+GPIO2::X4_LEDGRN)
                @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_LEDYEL) # X4_LEDYEL
            end
        end
    end

    def runTCUSampler
        @gPIO2 = GPIO2.new
        @gPIO2.getForInitGetImagesOf16Addrs

        @logRptAvgCt = 0
        @socketIp = nil
    	@setupAtHome = true # So we can do some work at home
    	@initMuxValueFunc = false
    	@initpollAdcInputFunc = false
        @allDutTempTolReached = false
        @multiplier = Hash.new
        @highestStepNumber = -1
        @isOkToLog = false

        @samplerData = SharedMemory.new
    	@samplerData.SetupData()
    	@samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
    	
        turnOffHeaters()
    	initMuxValueFunc()
    	initpollAdcInputFunc()
    	readInBbbDefaultsFile()
    	readInEthernetScheme()

        # runThreadForSavingSlotStateEvery10Mins()
        # runThreadForPcCmdInput()

		# DRb are the two lines below
		DRb.start_service
		@sharedMemService = DRbObject.new_with_uri(SERVER_URI)
        
        # Setup the UART comm.
        baudrateToUse = 115200 # baud rate options are 9600, 19200, and 115200
        system("cd /lib/firmware")
        system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots")
        system("stty -F /dev/ttyO1 raw")
    	system("stty -F /dev/ttyO1 #{baudrateToUse}")
    	system("./openTtyO1Port_115200.exe")
        uart1 = UARTDevice.new(:UART1, baudrateToUse)

        SharedLib.bbbLog("Initializing machine using system's time. #{__LINE__}-#{__FILE__}")
        
        @tcusToSkip = Hash.new
=begin        
        # Read the file that lists the dead TCUs.
        lineNum = 0
        SharedLib.bbbLog("Processing '#{FaultyTcuList_SkipPolling}' file. #{__LINE__}-#{__FILE__}")
	    begin
    		File.open(FaultyTcuList_SkipPolling, "r") do |f|
    			f.each_line do |line|
    			    # puts "Puts line read = #{line}.  #{__LINE__}-#{__FILE__}"
    			    if lineNum>0
    			        # puts "Processing '#{line}'.  #{__LINE__}-#{__FILE__}"
    			        readLine = line.chomp
        			    if SharedLib.is_a_number?(readLine)
        			        intVal = readLine.to_i
        			        @tcusToSkip[intVal] = intVal
        			        # puts "Skipping TCU(#{intVal}) based on file list. #{__LINE__}-#{__FILE__}"
        			    else
        			        SharedLib.bbbLog("Not processing line# '#{lineNum+1}' on file '#{FaultyTcuList_SkipPolling}' because it's not a number. #{__LINE__}-#{__FILE__}")
        			    end
    			    end
    				lineNum += 1
        		end
    		end
		    rescue Exception => e
		        SharedLib.bbbLog("Error: #{e.message}  #{__LINE__}-#{__FILE__}")
	    end
=end        

        SharedLib.bbbLog "Searching for disabled TCUs aside the listed ones in '#{FaultyTcuList_SkipPolling}' file. #{__LINE__}-#{__FILE__}"
        ct = 0
        newDeadTcu = false
        dutObj = DutObj.new()
        while ct<24 && @tcusToSkip[ct].nil? do 
            uartResponse = DutObj::getTcuStatusS(ct,uart1,@gPIO2)
            if uartResponse == DutObj::FaultyTcu
                @tcusToSkip[ct] = ct
                newDeadTcu = true
                SharedLib.bbbLog("UART not responding to TCU#{ct} (zero based index), adding item to be skipped when polling. #{__LINE__}-#{__FILE__}")
            else
                # puts "Sent 'S?' - responded :'#{uartResponse}' #{__LINE__}-#{__FILE__}"
                uart1.write("V?\n");
                x = uart1.readline
                # puts "Sent 'V?' - responded :'#{x}' #{__LINE__}-#{__FILE__}"
            end
            ct += 1
        end

=begin        
        if newDeadTcu
            # Write the new FaultyTcuList file
            SharedLib.bbbLog "Updating #{FaultyTcuList_SkipPolling} file due to new faulty TCU.  See log."
    	    File.open(FaultyTcuList_SkipPolling, "w") { 
    	        |file| 
    	        file.write("This file lists the TCUs that are to be skipped when running the system.  Items not listed during initial boot might be added in this list by the system if UART don't reply properly.\n")
    	        ct = 0
    	        while ct<24 do
    	            if @tcusToSkip[ct].nil? == false
    	                file.write("#{ct}\n") 
    	                puts "Wrote #{ct} into file. #{__LINE__}-#{__FILE__}"
    	            end
    	            ct += 1
    	        end
            }
        end
=end

        # Make sure that the UART is functional again.        

        #
        # Get the board configuration
        #
        SharedLib.bbbLog("Get board configuration from holding tank. #{__LINE__}-#{__FILE__}")
        loadConfigurationFromHoldingTank(uart1)
        
        if @boardData[Configuration].nil? == false && @boardData[Configuration][FileName].nil? == false
	        @samplerData.SetConfigurationFileName(@boardData[Configuration][FileName])
	    else
	        @samplerData.SetConfigurationFileName("")
        end
        
        if @boardData[Configuration].nil? == false && @boardData[Configuration]["ConfigDateUpload"].nil? == false
    	    @samplerData.SetConfigDateUpload(@boardData[Configuration]["ConfigDateUpload"])
    	else
    	    @samplerData.SetConfigDateUpload("")
        end

        if @boardData[SharedLib::AllStepsDone_YesNo].nil? == false
            @samplerData.SetAllStepsDone_YesNo(@boardData[SharedLib::AllStepsDone_YesNo],"#{__LINE__}-#{__FILE__}")
        else
            @samplerData.SetAllStepsDone_YesNo(SharedLib::Yes,"#{__LINE__}-#{__FILE__}") # so it will not run
        end
        
        setTcuToStopMode() # turnOffDuts(@tcusToSkip)
        
	    initStepToWorkOnVar(uart1)
        if @stepToWorkOn.nil? == false
            # PP.pp(@stepToWorkOn)
            # puts "Printing @stepToWorkOn content. #{__LINE__}-#{__FILE__}"
            limboCheck(@stepToWorkOn[StepNum],uart1)
        end
        
        @totDutTempReached = 0
        @totDutsAvailable = 0

        @loggingTime = 60.to_i # 5 seconds for now
        pollingTime = 1 # check every second
        pollIntervalInSeconds = pollingTime
        skipLimboStateCheck = false
        
        turnBuzzerOnAt = Time.now
        buzzerBackOn = true
        
        # @samplerData.ReportError("Error test. #{__LINE__}-#{__FILE__}")
        @timeOfLog = Time.now
        while true
            stepNum = ""
            if @stepToWorkOn.nil? == false
                # PP.pp(@stepToWorkOn)
                # puts "Printing @stepToWorkOn content. #{__LINE__}-#{__FILE__}"
                stepNum = @stepToWorkOn[StepNum]
            end
            
            if @samplerData.GetConfigurationFileName().length>0
                cfgName = "Yes"
            else
                cfgName = "No"
            end
            
            if @stepToWorkOn.nil? == false
                tw = @stepToWorkOn[SharedMemory::TempWait]
                ctw = @stepToWorkOn[CalculatedTempWait]
                if @waitTempStartTime.nil?
                    wts = 0
                else
                    wts = @waitTempStartTime
                end
                twtimeleft = (ctw-(Time.now.to_f-wts)).to_i
            else
                tw = SharedLib::DashLines
                ctw = SharedLib::DashLines
                twtimeleft = SharedLib::DashLines
            end
            puts "Mode()=#{@samplerData.GetBbbMode()} Done()=#{@samplerData.GetAllStepsDone_YesNo()} CfgName()=#{cfgName} stepNum=#{stepNum} temp time wait left ='#{twtimeleft}' #{Time.now.inspect} #{__LINE__}-#{__FILE__}"
            @samplerData.SetSlotTime(Time.now.to_i)
            if skipLimboStateCheck
                skipLimboStateCheck = false
            else
                limboCheck(stepNum,uart1)
            end
    
			case @samplerData.GetBbbMode()
			when SharedLib::InRunMode
			    if @boardData[SharedLib::AllStepsDone_YesNo] == SharedLib::No
    			    if @stepToWorkOn.nil?
    			        # There are no more steps to process.
    			        # All the steps are done processing.
    			        # setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
    			        setAllStepsDone_YesNo(SharedLib::Yes,"#{__LINE__}-#{__FILE__}")
    			    else
    			        evaluatedDevices(pollIntervalInSeconds, pollingTime, uart1, twtimeleft)
    			    end
    			elsif @boardMode == SharedLib::InRunMode
    			    # Setting to stop mode because all steps are done already and the boardMode is still in run mode.
    			    setToMode(SharedLib::InStopMode,"#{__LINE__}-#{__FILE__}")
			    end
            end
            
            memFromService = @sharedMemService.getSharedMem()
    		pcCmdObj = memFromService.GetPcCmd()
    		if pcCmdObj.nil? == false && pcCmdObj.length > 0
	            @samplerData.SetSlotOwner(memFromService.dataFromPCGetSlotOwner())
    		    pcCmd = pcCmdObj[0]
    		    timeOfCmd = pcCmdObj[1]
    		    if @lastTimeOfCmd != timeOfCmd # @lastPcCmd != pcCmd && 
    		        puts "new pc command. #{pcCmdObj}"
                    @lastPcCmd = pcCmd 
                    @lastTimeOfCmd = timeOfCmd
                    @lastSettings = -1
        		    puts "\n\n\nNew command from PC - '#{pcCmd}' @samplerData.GetPcCmd().length='#{pcCmdObj.length}'  #{__LINE__}-#{__FILE__}"
                    @samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
        		    case pcCmd
        		    when SharedLib::RunFromPc
    		            setToMode(SharedLib::InRunMode,"#{__LINE__}-#{__FILE__}")
                        @samplerData.clearStopMessage()
                        
        		    when SharedLib::StopFromPc
        		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
                        
        		    when SharedLib::ClearConfigFromPc
                        @samplerData.clearStopMessage()
        		        @samplerData.ClearConfiguration("#{__LINE__}-#{__FILE__}")
                        @samplerData.setErrorColor(nil)
            		    setBoardData(Hash.new,uart1)
        		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
        		        setBoardStateForCurrentStep(uart1)
            		    @samplerData.SetConfigurationFileName("")
            		    @gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_P12V|GPIO2::W3_N5V|GPIO2::W3_P5V)
                        
        		    when SharedLib::LoadConfigFromPc
                        @samplerData.clearStopMessage()
        		        @lotStartedAlready = false
        		        @boardData[LastStepNumOfSentLog] = -1 # initial value
        		        
        		        # close the sockets of the Ethernet PS if they're on.
        		        @ethernetPS = nil # Reset the check for new configuration.
        		        if @socketIp.nil? == false
                            @socketIp.each do |key, array|
                                if @socketIp[key].nil? == false
                                    @socketIp[key].close
                                end
                            end                		    
        		        end
        		        @socketIp = nil
        		        
                        #SharedLib.bbbLog("New configuration step file uploaded.")
                        @samplerData.SetConfiguration(memFromService.getHashConfigFromPC(),"#{__LINE__}-#{__FILE__}")
            		    setBoardData(Hash.new,uart1)
            		    
            		    @boardData[Configuration] = @samplerData.GetConfiguration()
                        @samplerData.setErrorColor(nil)
            		    @samplerData.SetConfigurationFileName(@boardData[Configuration][FileName])
            		    @samplerData.SetConfigDateUpload(@boardData[Configuration]["ConfigDateUpload"])
            		    
                        setAllStepsDone_YesNo(SharedLib::No,"#{__LINE__}-#{__FILE__}")
        		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
        		        setBoardStateForCurrentStep(uart1)

            		    # Enable these bits.
            		    @gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_P12V|GPIO2::W3_N5V|GPIO2::W3_P5V)
            		    
            		    # Get the highest number of step.
            		    
            		    @boardData[HighestStepNumber] = -1
                        getConfiguration()[Steps].each do |key, array|
                            getConfiguration()[Steps][key].each do |key2, array2|
                                # Get which step to work on and setup the power supply settings.
                                if key2 == StepNum 
                                    if @boardData[HighestStepNumber] < getConfiguration()[Steps][key][key2].to_i
                                        @boardData[HighestStepNumber] = getConfiguration()[Steps][key][key2].to_i
                                    end
                                end
                            end
                        end

            		    
            		    skipLimboStateCheck = true
            		else
            		    SharedLib.bbbLog("Unknown PC command @samplerData.GetPcCmd()='#{@samplerData.GetPcCmd()}'.")
            		end
            		puts "@stepToWorkOn.nil?=#{@stepToWorkOn.nil?} #{__LINE__}-#{__FILE__}"
        		    # Code block below tells the PcListener that it got the message.

                end
    		end


            #
            # Gather data regardless of whether it's in run mode or not...
            #
            pollAdcInput()
            pollMuxValues()
            ThermalSiteDevices.pollDevices(uart1,@gPIO2,@tcusToSkip)
            ThermalSiteDevices.logData(@samplerData)
            getEthernetPsCurrent()
            backFansHandler()
            runAwayTempHandler() # Need to verify this code.
            lightsAndBuzzerHandler(cfgName)
            
        	# This line of code makes the 'Sender' process useless.  This gives the fastest time of data update to the display.
        	SendSampledTcuToPCLib::SendDataToPC(@samplerData,"#{__LINE__}-#{__FILE__}")
            #
            # What if there was a hiccup and waitTime-Time.now becomes negative
            #
            sleep(0.01) # Get some sleep time so the Grape app will be a bit more responsive.
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
# 763
# 717
# [ ] Get the logger polished out
# [ ] Get the GUI Finish
# [ ] Test the run-away temps

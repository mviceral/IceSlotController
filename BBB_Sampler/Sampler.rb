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
    StepTimeLeft = "StepTimeLeft"
    TimeOfRun = "TimeOfRun"
    StepTime = "Step Time"
    StepNum = "Step Num"
    ForPowerSupply = "ForPowerSupply"
    PollIntervalInSeconds = "PollIntervalInSeconds"   
    HoldingTankFilename = "MachineState_DoNotDeleteNorModify.json"
    FaultyTcuList_SkipPolling = "../TcuDisabledSites.txt"
    TimeOfPcLastCmd ="TimeOfPcLastCmd"
    BbbMode = "BbbMode"
    SeqDownPsArr = "SeqDownPsArr"
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
    SeqUpLogger = "SeqUp"
    SeqDownLogger = "SeqDown"
    VMeas = "VMeas"
    IMeas = "IMeas"
    Temp1 = "Temp1"
    Temp2 = "Temp2"
    
    DutNum= " DUT#"
    DutStatus = "        DUT status"
    DutTemp = "  Temp"
    DutCurrent = "Current"
    DutHeatDuty = "HEAT duty%"
    DutControllerTemp = "Controller temp"
    DutPwmOutput = "PwmOutput"
    
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
                psSeqUp()
                setTimeOfRun()
                # setPollIntervalInSeconds(IntervalSecInRunMode,"#{__LINE__}-#{__FILE__}")
            else
                # setPollIntervalInSeconds(IntervalSecInStopMode,"#{__LINE__}-#{__FILE__}")
                #
                # Calculate the total time left before sequencing down.
                #
                if @stepToWorkOn.nil? == false
                    @stepToWorkOn[StepTimeLeft] = @stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun())
                end
                psSeqDown("#{__LINE__}-#{__FILE__}")
                @samplerData.setWaitTempMsg("")
            end
            
            saveBoardStateToHoldingTank()
        else
            SharedLib.bbbLog("Don't recognize modeParam=#{modeParam}, calledFrom=#{calledFrom}")
            SharedLib.bbbLog("Exiting code.")
            exit
        end
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
                    @samplerData.ReportError("Cannot open Ethernet power supply socket on IP='#{host}'.  This power supply will be disabled.")
                	SendSampledTcuToPCLib::SendDataToPC(@samplerData,"#{__LINE__}-#{__FILE__}")
                end
            end
        end
    end                                                            

    def initStepToWorkOnVar(uart1)
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
    
    def stopMachineIfTripped(gPIO2Param, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
        # puts "'#{key2}' checking for trip points. #{__LINE__}-#{__FILE__}"
        if @disabledPS.include?(key2) == false
            # puts "'#{key2}' is not disabled.  Checking for trip points."
            # @samplerData.ReportError("key2 = #{key2}, tripMin='#{tripMin}', actualValue='#{actualValue}', tripMax='#{tripMax}', flagTolP='#{flagTolP}', flagTolN='#{flagTolN}'")
            
            unit = key2[0]
            if unit == "I"
                unit = "A"
            end
            
            if (flagTolP <= actualValue && actualValue <= flagTolN) == false
                @samplerData.ReportError("NOTICE - #{key2} out of bound flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed.  .")
            end

            if (tripMin <= actualValue && actualValue <= tripMax) == false
                stopMachine()
                @samplerData.ReportError("ERROR - #{key2} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE.")
                return true                
            end
        end
        return false
    end
    
    def stopMachine()
        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
                
        # Turn on the control for TCUs that are not disabled.
        setTcuToStopMode() # turnOffDuts(@tcusToSkip)
        
        @samplerData.setWaitTempMsg("")
        @samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
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
    	@multiplier[SharedLib::IPS6] = 2.0
    	@multiplier[SharedLib::IPS8] = 5.0
    	@multiplier[SharedLib::IPS9] = 5.0
    	@multiplier[SharedLib::IPS10] = 5.0
    	@multiplier[SharedLib::SPARE] = 5.0
    	@multiplier[SharedLib::IP5V] = 5.0
    	@multiplier[SharedLib::IP12V] = 10.0
    	@multiplier[SharedLib::IP24V] = 10.0
    	@multiplier[SharedLib::VPS0] = 2.300
    	@multiplier[SharedLib::VPS1] = 2.300
    	@multiplier[SharedLib::VPS2] = 2.300
    	@multiplier[SharedLib::VPS3] = 2.300
    	@multiplier[SharedLib::VPS4] = 2.300
    	@multiplier[SharedLib::VPS5] = 2.300
    	@multiplier[SharedLib::VPS6] = 2.300
    	@multiplier[SharedLib::VPS7] = 2.300
    	@multiplier[SharedLib::VPS8] = 4.010
    	@multiplier[SharedLib::VPS9] = 4.010
    	@multiplier[SharedLib::VPS10] = 4.010
    	@multiplier[SharedLib::BIBP5V] = 4.010
    	@multiplier[SharedLib::BIBN5V] = 4.010
    	@multiplier[SharedLib::BIBP12V] = 9.660
    	@multiplier[SharedLib::P12V] = 9.660
    	@multiplier[SharedLib::P24V] = 20.100
    end
    
    def initpollAdcInputFunc()
    	@initpollAdcInputFunc = true
    	@multiplier[SharedLib::SLOTP5V] = 4.01
    	@multiplier[SharedLib::SLOTP3V3] = 2.3
    	@multiplier[SharedLib::SLOTP1V8] = 2.3
    	@multiplier[SharedLib::SlotTemp1] = 100.0
    	@multiplier[SharedLib::CALREF] = 2.3
    	@multiplier[SharedLib::SlotTemp2] = 100.0
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
    
    
    def makeItFitMeas(itemToPrint,column)
        itemToPrint = itemToPrint.to_s
        column = column.to_s
        while itemToPrint.length < column.length
            itemToPrint += "0"
        end
        return itemToPrint
    end

    def makeItFit(itemToPrint,column)
        itemToPrint = itemToPrint.to_s
        while itemToPrint.length < column.length
            itemToPrint = " "+itemToPrint
        end
        return itemToPrint
    end

    def sendToLogger(tbs)
        if tbs.length>0
            # There's some data to log.
            slotInfo = Hash.new()
            slotInfo[SharedLib::DataLog] = tbs
            slotInfo[SharedLib::SlotOwner] = @samplerData.GetSlotOwner# GetSlotIpAddress()
            slotInfo[SharedLib::ConfigurationFileName] = @samplerData.GetConfigurationFileName()
            slotInfo[SharedLib::ConfigDateUpload] = @samplerData.GetConfigDateUpload()
            slotInfoJson = slotInfo.to_json
            SendSampledTcuToPCLib::sendSlotInfoToPc(slotInfoJson)
        end
    end
    
    def turnOffHeaters
        @gPIO2.setBitOff(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
    end
    
    def fanCtrl(pwmParam, fanParam)
        @gPIO2.slotFanPulseWidthModulator(pwmParam)
        case fanParam
        when 0
            @gPIO2.slotCntlExtSet(0)
        when 1
            @gPIO2.slotCntlExtSet(GPIO2::X4_FAN1)
        when 2
            @gPIO2.slotCntlExtSet(GPIO2::X4_FAN2)
        when 3
            @gPIO2.slotCntlExtSet(GPIO2::X4_FAN1+GPIO2::X4_FAN2)
        else
            @samplerData.ReportError("fanParam='#{fanParam}' is wrong.  Expect value 0-3. #{__LINE__}-#{__FILE__}")
        end
    end
    
    # Set the values only one time
    FanPwm0 = 1
    FanPwm1 = FanPwm0+1
    FanPwm2 = FanPwm1+1
    FanPwm3 = FanPwm2+1
    FanPwm4 = FanPwm3+1
    FanPwm5 = FanPwm4+1
    FanPwm6 = FanPwm5+1
    FanPwm7 = FanPwm6+1
    FanPwm8 = FanPwm7+1
    FanPwm9 = FanPwm8+1
    FanPwm10 = FanPwm9+1
    FanPwm11 = FanPwm10+1
    FanPwm12 = FanPwm11+1
    FanPwm13 = FanPwm12+1
    FanPwm14 = FanPwm13+1
    FanPwm15 = FanPwm14+1
    FanPwm16 = FanPwm15+1
    FanPwm17 = FanPwm16+1
    FanPwm18 = FanPwm17+1
    FanPwm19 = FanPwm18+1
    FanPwm20 = FanPwm19+1
    FanPwm21 = FanPwm20+1

    def backFansHandler
        adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
        temp1Param = (adcInput[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(4)
        fanParam = 3
        if 20.0 <= temp1Param && temp1Param < 25.0
            fanCtrl(FanPwm0, fanParam)
        elsif 25.0 <= temp1Param && temp1Param < 30.0
            fanCtrl(FanPwm1, fanParam)
        elsif 30.0 <= temp1Param && temp1Param < 35.0
            fanCtrl(FanPwm2, fanParam)
        elsif 35.0 <= temp1Param && temp1Param < 40.0
            fanCtrl(FanPwm3, fanParam)
        elsif 40.0 <= temp1Param && temp1Param < 45.0
            fanCtrl(FanPwm4, fanParam)
        elsif 45.0 <= temp1Param && temp1Param < 50.0
            fanCtrl(FanPwm5, fanParam)
        elsif 50.0 <= temp1Param && temp1Param < 55.0
            fanCtrl(FanPwm6, fanParam)
        elsif 55.0 <= temp1Param && temp1Param < 60.0
            fanCtrl(FanPwm7, fanParam)
        elsif 60.0 <= temp1Param && temp1Param < 65.0
            fanCtrl(FanPwm8, fanParam)
        elsif 65.0 <= temp1Param && temp1Param < 70.0
            fanCtrl(FanPwm9, fanParam)
        elsif 70.0 <= temp1Param && temp1Param < 75.0
            fanCtrl(FanPwm10, fanParam)
        elsif 75.0 <= temp1Param && temp1Param < 80.0
            fanCtrl(FanPwm11, fanParam)
        elsif 80.0 <= temp1Param && temp1Param < 85.0
            fanCtrl(FanPwm12, fanParam)
        elsif 85.0 <= temp1Param && temp1Param < 90.0
            fanCtrl(FanPwm13, fanParam)
        elsif 90.0 <= temp1Param && temp1Param < 95.0
            fanCtrl(FanPwm14, fanParam)
        elsif 95.0 <= temp1Param && temp1Param < 100.0
            fanCtrl(FanPwm15, fanParam)
        elsif 100.0 <= temp1Param && temp1Param < 105.0
            fanCtrl(FanPwm16, fanParam)
        elsif 105.0 <= temp1Param && temp1Param < 110.0
            fanCtrl(FanPwm17, fanParam)
        elsif 110.0 <= temp1Param && temp1Param < 115.0
            fanCtrl(FanPwm18, fanParam)
        elsif 115.0 <= temp1Param && temp1Param < 120.0
            fanCtrl(FanPwm19, fanParam)
        elsif 120.0 <= temp1Param && temp1Param < 125.0
            fanCtrl(FanPwm20, fanParam)
        elsif 125.0 <= temp1Param && temp1Param < 130.0
            fanCtrl(FanPwm21, fanParam)
        end
    end
    
    def runTCUSampler
        @gPIO2 = GPIO2.new
        @gPIO2.getForInitGetImagesOf16Addrs

        @socketIp = nil
    	@setupAtHome = true # So we can do some work at home
    	@initMuxValueFunc = false
    	@initpollAdcInputFunc = false
        @allDutTempTolReached = false
        @multiplier = Hash.new
    	
        @samplerData = SharedMemory.new
    	@samplerData.SetupData()
    	@samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
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
        loggingTime = 60 # 5 seconds for now
        pollingTime = 1 # check every second
        pollIntervalInSeconds = pollingTime
        skipLimboStateCheck = false
        # @samplerData.ReportError("Error test. #{__LINE__}-#{__FILE__}")
        timeOfLog = Time.now
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
                tw = "---"
                ctw = "---"
                twtimeleft = "---"
            end
            puts "Mode()=#{@samplerData.GetBbbMode()} Done()=#{@samplerData.GetAllStepsDone_YesNo()} CfgName()=#{cfgName} stepNum=#{stepNum} ctw='#{ctw}', tw='#{tw}', temp time wait left ='#{twtimeleft}' #{Time.now.inspect} #{__LINE__}-#{__FILE__}"
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
    			        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
    			        setAllStepsDone_YesNo(SharedLib::Yes,"#{__LINE__}-#{__FILE__}")
    			    else
		                puts "@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)=#{@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)}  #{__LINE__}-#{__FILE__}"
        			    if @stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun)>0
        			        # We're still running.
        			        
        			        tcuData = @samplerData.parseOutTcuData(@samplerData.GetDataTcu("#{__LINE__}-#{__FILE__}"))
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
                                                actualValue = 0.9
                                            end
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax,flagTolP,flagTolN)
                                                break
                                            end
                                       when "IPS0"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS1"
			                                # puts "PS1V = #{@samplerData.getPsVolts(muxData,adcData,"33")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"33").to_f
                                            if @setupAtHome
                                                actualValue = 0.9
                                            end
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS1"
			                                # puts "PS1I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,key2)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS2"
			                                # puts "PS2V = #{@samplerData.getPsVolts(muxData,adcData,"34")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"34").to_f
                                            if @setupAtHome
                                                actualValue = 1.5
                                            end
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS2"
			                                # puts "PS2I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,key2)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS3"
			                                # puts "PS3V = #{@samplerData.getPsVolts(muxData,adcData,"35")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"35").to_f
                                            if @setupAtHome
                                                actualValue = 0.9
                                            end
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS3"
			                                # puts "PS3I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,key2)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS4"
			                                # puts "PS4V = #{@samplerData.getPsVolts(muxData,adcData,"36")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"36").to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS4"
			                                # puts "PS4I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,"IPS2")}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,"IPS2").to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS5"
			                                # puts "PS5V = #{@samplerData.getPsVolts(muxData,adcData,"37")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"37").to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS5"
			                                # puts "PS5I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,nil).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS6"
			                                # puts "PS6V = #{@samplerData.getPsVolts(muxData,adcData,"38")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"38").to_f
                                            if @setupAtHome
                                                actualValue = 3.3
                                            end
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS6"
			                                # puts "PS6I = #{@samplerData.getPsCurrent(muxData,eiPs,"24",nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"24",nil).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS7"
			                                # puts "PS7V = #{@samplerData.getPsVolts(muxData,adcData,"39")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"39").to_f
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if @setupAtHome
                                                actualValue = 0.9
                                            end
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS7"
			                                # puts "PS7I = #{@samplerData.getPsCurrent(muxData,eiPs,nil,nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,nil,key2).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS8"
			                                # puts "PS8V = #{@samplerData.getPsVolts(muxData,adcData,"40")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"40").to_f
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if @setupAtHome
                                                actualValue = 5.0
                                            end
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS8"
			                                # puts "PS8I = #{@samplerData.getPsCurrent(muxData,eiPs,"25",nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"25",nil).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS9"
			                                # puts "PS9V = #{@samplerData.getPsVolts(muxData,adcData,"41")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"41").to_f
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if @setupAtHome
                                                actualValue = 2.1
                                            end
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS9"
			                                # puts "PS9I = #{@samplerData.getPsCurrent(muxData,eiPs,"26",nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"26",nil).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "VPS10"
			                                # puts "PS10V = #{@samplerData.getPsVolts(muxData,adcData,"42")}"
                                            actualValue = @samplerData.getPsVolts(muxData,adcData,"42").to_f
                                            #@samplerData.ReportError("#{key2} value fudged to pass on line #{__LINE__}-#{__FILE__}")
                                            if @setupAtHome
                                                actualValue = 2.5
                                            end
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IPS10"
                                            # puts "PS10I = #{@samplerData.getPsCurrent(muxData,eiPs,"27",nil)}"
                                            actualValue = @samplerData.getPsCurrent(muxData,eiPs,"27",nil).to_f
                                            if stopMachineIfTripped(@gPIO2, key2, tripMin, actualValue, tripMax, flagTolP, flagTolN)
                                                break
                                            end
                                        when "IDUT"
                                            unit = "A"
                                            ct = 0
                                            while ct<24 do
                                                if @tcusToSkip[ct].nil? == true
                            						puts "dutI#{ct} = '#{SharedLib.getCurrentDutDisplay(muxData,"#{ct}")}'"
                                                    actualValue = SharedLib.getCurrentDutDisplay(muxData,"#{ct}").to_f
                                                    if (flagTolP <= actualValue && actualValue <= flagTolN) == false
                                                        @samplerData.ReportError("NOTICE - IDUT#{ct} out of bound flag points.  '#{flagTolP}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolN}'#{unit} failed.  .")
                                                        ct = 24 # break out of the loop.
                                                    end
                                                    if (tripMin <= actualValue && actualValue <= tripMax) == false
                                                        stopMachine()
                                                        @samplerData.ReportError("ERROR - IDUT#{ct} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE.")
                                                        ct = 24 # break out of the loop.
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
                                                @samplerData.ReportError("key='#{key2}' is not recognized. #{__LINE__}-#{__FILE__}")
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
                                            totDutTempReached = 0
                                            totDutsAvailable = 0
                                            tempTolP = flagTolP
                                            tempTolN = flagTolN
                            				while dutCt<24 
                            					if tcuData.nil? == false && tcuData["#{dutCt}"].nil? == false 
            						                splitted = tcuData["#{dutCt}"].split(',')
                            						temperature = SharedLib::make5point2Format(splitted[2]).to_f
                                                    puts "dut##{dutCt} flagTolP='#{flagTolP}' <= temp='#{temperature}' <= #{flagTolN} : '#{flagTolP<=temperature && temperature<=flagTolN}'"
                                				    if flagTolP<=temperature && temperature<=flagTolN
                                				        if @dutTempTolReached[dutCt].nil?
                                    				        @dutTempTolReached[dutCt] = true
                                				        end
                                				    end
                                				    
                                				    if @dutTempTolReached[dutCt] == true
                                				        totDutTempReached += 1
                                				    end
                                				    totDutsAvailable += 1
                                                end
                            				    dutCt += 1
                            				end
                            				
                            				if @allDutTempTolReached == false && @stepToWorkOn[CalculatedTempWait]-(Time.now.to_f-@waitTempStartTime)<0
                            				    totDutTempReached = totDutsAvailable
                            				end

                            				if totDutTempReached == totDutsAvailable
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
                                            puts "totDutTempReached='#{totDutTempReached}'/'#{totDutsAvailable}' @allDutTempTolReached = '#{@allDutTempTolReached}'"
                            				
                                            if @allDutTempTolReached
                                                if tcuData.nil?
                                                    dutCt = 0
                                                    unit = "C"
                                    				while dutCt<24 
                						                splitted = tcuData["#{dutCt}"].split(',')
                                						actualValue = SharedLib::make5point2Format(splitted[2])
                                                        if (flagTolN <= actualValue && actualValue <= flagTolP) == false
                                                            @samplerData.ReportError("NOTICE - DUT##{dutCt} out of bound within flag points.  '#{flagTolN}'#{unit} <= '#{actualValue}'#{unit} <= '#{flagTolP}'#{unit} failed.  .")
                                                        end
                                            
                                                        if (tripMin <= actualValue && actualValue <= tripMax) == false
                                                            puts "trip points failure. #{__LINE__}-#{__FILE__}"
                                                            stopMachine()
                                                            dutCt = 24 
                                                            @samplerData.ReportError("ERROR - DUT##{dutCt} OUT OF BOUND TRIP POINTS!  '#{tripMin}'#{unit} <= '#{actualValue}'#{unit} <= '#{tripMax}'#{unit} FAILED.  GOING TO STOP MODE.")
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
                                                @samplerData.ReportError("key='#{key2}' is not recognized. #{__LINE__}-#{__FILE__}")
                                            end
                                        end                    			            
                                    end
                                else
                                    if @otherStuff.nil?
                                        # Make the list a global var so it will not keep creating the list per loop.
                                        @otherStuff = ['xStdep Num','Step Time','TEMP WAIT','Alarm Wait','Auto Restart','Stop on Tolerance','StepTimeLeft','TIMERRUFP','TIMERRDFP']
                                    end
                                    
                                    if @otherStuff.include? key == false
                                        @samplerData.ReportError("key='#{key}' is not recognized. #{__LINE__}-#{__FILE__}")
                                    end
                                end
                            end
                            # We're in run mode.
                            if pollIntervalInSeconds == pollingTime
                                # The board started processing.
                                pollIntervalInSeconds = loggingTime
                            end
                            
                            if @allDutTempTolReached                             
                                tbs = ""
    
                                if @boardData[LastStepNumOfSentLog] != @samplerData.GetStepNumber()
                                    @boardData[LastStepNumOfSentLog] = @samplerData.GetStepNumber()
                                    timeOfLog = Time.new.to_i
                                    puts "Sending log data.  #{Time.now.inspect}. #{__LINE__}-#{__FILE__}"
                                    tbs  = "BIB#: #{@ethernetScheme[SlotBibNum]}\n"
                                    tbs  = "Test Step: step##{@samplerData.GetStepNumber()}-#{@samplerData.GetStepName()}\n"
                                    tbs += "Power Supply Setting:\n"
                                    tbs += "#{PSNameLogger}|#{NomSetLogger}|#{TripMinLogger}|#{TripMaxLogger}|#{FlagTolPLogger}|#{FlagTolNLogger}|#{SeqUpLogger}|#{SeqDownLogger}\n"
                                    @stepToWorkOn["PsConfig"].each do |key, array|
                                        if key[0] == "V"
                                            tbs += "#{makeItFit(key,PSNameLogger)}|"
                                            tbs += "#{makeItFitMeas(array["NomSet"],5)}|"
                                            tbs += "#{makeItFitMeas(array["TripMin"],5)}|"
                                            tbs += "#{makeItFitMeas(array["TripMax"],5)}|"
                                            tbs += "#{makeItFitMeas(array["FlagTolP"],5)}|"
                                            tbs += "#{makeItFitMeas(array["FlagTolN"],5)}|"
                                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]]["SeqUp"],SeqUpLogger)}|"
                                            tbs += "#{makeItFit(@stepToWorkOn["PsConfig"]["S"+key[1..-1]]["SeqDown"],SeqUpLogger)}\n"
                                        end
                                    end
                                    tbs += "Temperature Setting:\n"
                                    tbs += "#{PSNameLogger}|#{NomSetLogger}|#{TripMinLogger}|#{TripMaxLogger}|#{FlagTolPLogger}|#{FlagTolNLogger}\n"
                                    @stepToWorkOn["TempConfig"].each do |key, array|
                                        if key == "TDUT"
                                            tbs += "#{makeItFit(key,PSNameLogger)}|"
                                            tbs += "#{makeItFitMeas(array["NomSet"],5)}|"
                                            tbs += "#{makeItFitMeas(array["TripMin"],5)}|"
                                            tbs += "#{makeItFitMeas(array["TripMax"],5)}|"
                                            tbs += "#{makeItFitMeas(array["FlagTolP"],5)}|"
                                            tbs += "#{makeItFitMeas(array["FlagTolN"],5)}\n"
                                        end
                                    end
                                end
                                
                                if timeOfLog.to_i <= Time.now.to_i
                                    timeOfLog += pollIntervalInSeconds
                                    mins =  ((@samplerData.GetStepTimeLeft())/60.0).to_i
                                    secs =  (@samplerData.GetStepTimeLeft()-mins*60.0).to_i
                                    tbs += "Log Time Left: #{SharedLib::makeTime2colon2Format(mins,secs)} (mm:ss)\n"
                                    tbs += "#{DutNum}|#{DutStatus}|#{DutTemp}|#{DutCurrent}|#{DutHeatDuty}|#{DutControllerTemp}|#{DutPwmOutput}|\n"
                                    dutCt = 0
                                    muxData = @samplerData.GetDataMuxData("#{__LINE__}-#{__FILE__}")
                                    adcData = @samplerData.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
                                    eiPs = @samplerData.GetDataEips()
                                    # tbs += "eiPs=#{eiPs}\n"
                    				while dutCt<24
                    					dutIndex = "Dut#{dutCt}"
                    					if tcuData.nil? == false && tcuData["#{dutCt}"].nil? == false 
    						                splitted = tcuData["#{dutCt}"].split(',')
                                            tbs += "#{makeItFit(dutIndex,DutNum)}|"
                                            tbs += "#{makeItFit(splitted[5],DutStatus)}|"
                    						temperature = SharedLib::make5point2Format(splitted[2])
                                            tbs += "#{makeItFit(temperature,DutTemp)}|"
                                            tbs += "#{makeItFit(SharedLib.getCurrentDutDisplay(muxData,"#{dutCt}"),DutCurrent)}|"
                    						pWMoutput = splitted[4]
                    						if splitted[3] == "1"
                                                heatDuty = 0.0
                    						else
                                                heatDuty = SharedLib::make5point2Format(pWMoutput.to_f/255.0*100.0)
                    						end
                                            tbs += "#{makeItFit(heatDuty,DutHeatDuty)}|"
                    						controllerTemp = SharedLib::make5point2Format(splitted[1])
                                            tbs += "#{makeItFitMeas(controllerTemp,6)}|"
                                            tbs += "#{makeItFit(pWMoutput,DutPwmOutput)}\n"
                    					end
                    					dutCt += 1
                    				end # of 'while dutCt<24'
                                    # Supply 0 <V set> <V measured> <I measured>
                                    tbs += "#{PSNameLogger}|#{VMeas}|#{IMeas}\n"
                                    tbs += "#{makeItFit("VPS0",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"32"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS0"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS1",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"33"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS1"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS2",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"34"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS2"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS3",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"35"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS3"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS4",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"36"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS2"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS5",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"37"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"IPS5"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS6",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"38"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"24",nil),5)}\n"
    
                                    tbs += "#{makeItFit("VPS7",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"39"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,nil,"PS7"),5)}\n"
    
                                    tbs += "#{makeItFit("VPS8",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"40"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"25",nil),5)}\n"
    
                                    tbs += "#{makeItFit("VPS9",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"41"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"26",nil),5)}\n"
    
                                    tbs += "#{makeItFit("VPS10",PSNameLogger)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsVolts(muxData,adcData,"42"),5)}|"
                                    tbs += "#{makeItFitMeas(@samplerData.getPsCurrent(muxData,eiPs,"27",nil),5)}\n"
                                    tbs += "#{Temp1}|#{Temp2}\n"
    
                                    tbs += "#{makeItFitMeas((adcData[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(3),6)}|"
                                    tbs += "#{makeItFitMeas((adcData[SharedLib::SlotTemp2.to_s].to_f/1000.0).round(3),6)}\n"
                                    
                                end
                                
                                sendToLogger(tbs)
                                
                                @samplerData.SetStepTimeLeft(@stepToWorkOn[StepTimeLeft]-(Time.now.to_f-getTimeOfRun()))
                            else
                                @samplerData.setWaitTempMsg("#{tempTolP}C/#{tempTolN}C")
                            end
        			    else
        			        # We're done running.
                            @dutTempTolReached = Hash.new
                            @allDutTempTolReached = false
                        
                            sendToLogger("End Step (step##{@boardData[LastStepNumOfSentLog]})\n")
        			        # Step just finished.
                            # We're in polling mode.
                            if pollIntervalInSeconds == loggingTime
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
                                
                                setTcuToStopMode()
                                # We're done processing all the steps.
                            end
                        end
    			    end
    			elsif @boardMode == SharedLib::InRunMode
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
                    
    		        # getTimeOfPcLastCmd() < @samplerData.GetTimeOfPcLastCmd()
        		    puts "\n\n\nNew command from PC - '#{pcCmd}' @samplerData.GetPcCmd().length='#{pcCmdObj.length}'  #{__LINE__}-#{__FILE__}"
                    @samplerData.SetButtonDisplayToNormal(SharedLib::NormalButtonDisplay)
        		    case pcCmd
        		    when SharedLib::RunFromPc
        		        runMachine()
                        
        		    when SharedLib::StopFromPc
        		        stopMachine()
                        
        		    when SharedLib::ClearConfigFromPc
        		        @samplerData.ClearConfiguration("#{__LINE__}-#{__FILE__}")

            		    setBoardData(Hash.new,uart1)
        		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
        		        setBoardStateForCurrentStep(uart1)
            		    @samplerData.SetConfigurationFileName("")
            		    @gPIO2.setBitOff(GPIO2::PS_ENABLE_x3,GPIO2::W3_P12V|GPIO2::W3_N5V|GPIO2::W3_P5V)
            		    turnOffHeaters()
                        setTcuToStopMode() # turnOffDuts(@tcusToSkip)
                        
        		    when SharedLib::LoadConfigFromPc
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
        		        
                        setTcuToStopMode() # turnOffDuts(@tcusToSkip)
        		        
                        SharedLib.bbbLog("New configuration step file uploaded.")
                        @samplerData.SetConfiguration(memFromService.getHashConfigFromPC(),"#{__LINE__}-#{__FILE__}")

            		    setBoardData(Hash.new,uart1)
            		    @boardData[Configuration] = @samplerData.GetConfiguration()
            		    # puts "#{@boardData[Configuration]} - Checking @boardData[Configuration] content."
            		    @samplerData.SetConfigurationFileName(@boardData[Configuration][FileName])
            		    @samplerData.SetConfigDateUpload(@boardData[Configuration]["ConfigDateUpload"])
                        setAllStepsDone_YesNo(SharedLib::No,"#{__LINE__}-#{__FILE__}")
        		        setToMode(SharedLib::InStopMode, "#{__LINE__}-#{__FILE__}")
        		        setBoardStateForCurrentStep(uart1)
            		    saveBoardStateToHoldingTank()

            		    # Empty out the shared memory so we have more room in the memory.  Save at least 19k bytes of space
            		    # by clearing it out.
            		    # memFromService.SetConfiguration(nil,"#{__LINE__}-#{__FILE__}") 
            		    @gPIO2.setBitOn(GPIO2::PS_ENABLE_x3,GPIO2::W3_P12V|GPIO2::W3_N5V|GPIO2::W3_P5V)
            		    @gPIO2.setBitOn(GPIO2::EXT_SLOT_CTRL_x4,GPIO2::X4_POWER)
            		    skipLimboStateCheck = true
            		else
            		    SharedLib.bbbLog("Unknown PC command @samplerData.GetPcCmd()='#{@samplerData.GetPcCmd()}'.")
            		end
            		puts "@stepToWorkOn.nil?=#{@stepToWorkOn.nil?} #{__LINE__}-#{__FILE__}"
        		    setTimeOfPcLastCmd(@samplerData.GetTimeOfPcLastCmd())
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
            
        	# This line of code makes the 'Sender' process useless.  This gives the fastest time of data update to the display.
        	SendSampledTcuToPCLib::SendDataToPC(@samplerData,"#{__LINE__}-#{__FILE__}")
            #
            # What if there was a hiccup and waitTime-Time.now becomes negative
            #
            sleep(0.1) # Get some sleep time so the Grape app will be a bit more responsive.
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
# @ 1232

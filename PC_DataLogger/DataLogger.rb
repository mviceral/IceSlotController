require 'drb/drb'
require_relative '../lib/SharedLib'
require_relative '../lib/SharedMemory'

class DataLogger
	SERVER_URI="druby://localhost:8787"
	StepNumber = "Step#"
	TimeLeft = "Step Time-Left#"
	Dut = "DUT"
	$SAFE = 0
	def initialize
		DRb.start_service			
		@sharedMemService =  DRbObject.new_with_uri(SERVER_URI)
	end # End of initialize

	def addToIndexDataLog(indexLableParam)
		# This function is used such that added index headers will be display in the order of their insertion through this function.
		# For example, display data A,B,C,D, this function must be called in this fashion as well: 
		# addToIndexDataLog("A")
		# addToIndexDataLog("B")
		# addToIndexDataLog("C")
		# addToIndexDataLog("D")
		if @hashDataIndex[indexLableParam].nil?
			@arrDataLog.push(indexLableParam)
			@hashDataIndex[indexLableParam] = "" # make it NOT nil.
		else
			puts "ERROR!!!  indexLableParam='#{indexLableParam}' is already accounted! #{__LINE__}-#{__FILE__}"
			exit # Terminate the code...
		end
	end
	

	def setDataForLogging(hashIndexParam,dataParam)
		# The idea of this function is to ensure that the sent hashIndexParam is valid in order to display it correctly.
		# puts "called setDataForLogging hashIndexParam='#{hashIndexParam}', dataParam='#{dataParam}' #{__LINE__}-#{__FILE__}"
		if @hashDataIndex.nil?
			# below is the order of data display, comma delimited.
			@arrDataLog = Array.new
			@hashDataIndex = Hash.new
				
			addToIndexDataLog(StepNumber)
			addToIndexDataLog(TimeLeft)
			dutCt = 0
			while dutCt<24
				dutIndex = Dut+"#{dutCt}"
				addToIndexDataLog(dutIndex+" Current")
				addToIndexDataLog(dutIndex+" RunStopMode")
				addToIndexDataLog(dutIndex+" ControllerTemp")
				addToIndexDataLog(dutIndex+" DutTemp")
				addToIndexDataLog(dutIndex+" CoolHeatMode")
				addToIndexDataLog(dutIndex+" PwmOutput")
				addToIndexDataLog(dutIndex+" Status")
				dutCt += 1
			end
			
			addToIndexDataLog("PS0V")
			addToIndexDataLog("PS0I")
			addToIndexDataLog("PS1V")
			addToIndexDataLog("PS1I")
			addToIndexDataLog("PS2V")
			addToIndexDataLog("PS2I")
			addToIndexDataLog("PS3V")
			addToIndexDataLog("PS3I")
			addToIndexDataLog("PS4V")
			addToIndexDataLog("PS4I")
			addToIndexDataLog("PS5V")
			addToIndexDataLog("PS5I")
			addToIndexDataLog("PS6V")
			addToIndexDataLog("PS6I")
			addToIndexDataLog("PS7V")
			addToIndexDataLog("PS7I")
			addToIndexDataLog("PS8V")
			addToIndexDataLog("PS8I")
			addToIndexDataLog("PS9V")
			addToIndexDataLog("PS9I")
			addToIndexDataLog("PS10V")
			addToIndexDataLog("PS10I")
			addToIndexDataLog("P5V")
			addToIndexDataLog("N5V")
			addToIndexDataLog("P12V")
			addToIndexDataLog("5V")
			addToIndexDataLog("5I")
			addToIndexDataLog("12V")
			addToIndexDataLog("12I")
			addToIndexDataLog("24V")
			addToIndexDataLog("24I")
			addToIndexDataLog("SlotTemp1")
			addToIndexDataLog("SlotTemp2")
		end
		
		if @hashDataIndex[hashIndexParam].nil?
			puts "ERROR!!!  hashIndexParam='#{hashIndexParam}' is NOT added in the list accounted! #{__LINE__}-#{__FILE__}"
			exit # Terminate the code...
		else
			@hashForLog[hashIndexParam] = dataParam
		end
	end

	
	def logData(slotOwnerParam)
		@sharedMem = @sharedMemService.getSharedMem()
		$SAFE = 0
		# Get a fresh data...
		logInterval5Min = 2 #60*5
	
		if @newLog.nil?
			@newLog = Hash.new
		end
	
		if @newLog[slotOwnerParam].nil? 
			@newLog[slotOwnerParam] = true
		end
	
		if @lastLog.nil?
			@lastLog = Hash.new
		end
	
		if @lastLog[slotOwnerParam].nil?
			@lastLog[slotOwnerParam] = Time.new.to_i
		end

		if @sharedMem.getMemory()[SharedLib::PC][slotOwnerParam].nil? == false
			# There's data in this slot.
			if SharedLib::InRunMode == @sharedMem.GetDispBbbMode(slotOwnerParam) && @lastLog[slotOwnerParam] <= Time.new.to_i
				puts "logdata function - #{slotOwnerParam} time='#{Time.new.inspect}' @#{__LINE__}-#{__FILE__}"
				@hashForLog = Hash.new
				setDataForLogging(StepNumber,@sharedMem.GetDispStepNumber(slotOwnerParam))
				setDataForLogging(TimeLeft,@sharedMem.GetDispStepTimeLeft(slotOwnerParam))
				dutCt = 0
				while dutCt<24
					dutIndex = Dut+"#{dutCt}"

					if @sharedMem.GetDispTcu(slotOwnerParam).nil? == false && @sharedMem.GetDispTcu(slotOwnerParam )["#{dutCt}"].nil? == false
						tcuData = @sharedMem.GetDispTcu(slotOwnerParam)["#{dutCt}"]
					else
						tcuData = "-"
					end

					if tcuData == "-"
						modeRunStop = "-"
						controllerTemp = "-"
						temperature = "-"
						heatCoolMode = "-"
						pWMoutput = "-"
						status = "-"
						setDataForLogging(dutIndex+" RunStopMode","-")
						setDataForLogging(dutIndex+" ControllerTemp","-")
						setDataForLogging(dutIndex+" DutTemp","-")
						setDataForLogging(dutIndex+" CoolHeatMode","-")
						setDataForLogging(dutIndex+" PwmOutput","-")
						setDataForLogging(dutIndex+" Status","-")
						setDataForLogging(dutIndex+" Current","-")
					else
						splitted = tcuData.split(',')
						modeRunStop = splitted[0]
						if modeRunStop == "0"
							modeRunStop = "Run"
						else
							modeRunStop = "Stop"
						end				
						controllerTemp = SharedLib::make5point2Format(splitted[1])
						temperature = SharedLib::make5point2Format(splitted[2])
						if splitted[3] == "0"
							heatCoolMode = "COOL"
						else
							heatCoolMode = "HEAT"
						end				
						pWMoutput = splitted[4]
						status = splitted[5]
						setDataForLogging(dutIndex+" RunStopMode",modeRunStop)
						setDataForLogging(dutIndex+" ControllerTemp",controllerTemp)
						setDataForLogging(dutIndex+" DutTemp",temperature)
						setDataForLogging(dutIndex+" CoolHeatMode",heatCoolMode)
						setDataForLogging(dutIndex+" PwmOutput",pWMoutput)
						setDataForLogging(dutIndex+" Status",SharedLib::uriToStr(status))

						muxData = @sharedMem.GetDispMuxData(slotOwnerParam)
						setDataForLogging(dutIndex+" Current",SharedLib.getCurrentDutDisplay(muxData,"#{dutCt}"))
					end
		
					dutCt += 1
				end # of 'while dutCt<24'
				muxData = @sharedMem.GetDispMuxData(slotOwnerParam)
				adcData = @sharedMem.GetDispAdcInput(slotOwnerParam)
				eiPs = @sharedMem.GetDispEips(slotOwnerParam)

				setDataForLogging("PS0V",@sharedMem.getPsVolts(muxData,adcData,"32"))
				setDataForLogging("PS0I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS0"))
				setDataForLogging("PS1V",@sharedMem.getPsVolts(muxData,adcData,"33"))
				setDataForLogging("PS1I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS1"))
				setDataForLogging("PS2V",@sharedMem.getPsVolts(muxData,adcData,"34"))
				setDataForLogging("PS2I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS2"))
				setDataForLogging("PS3V",@sharedMem.getPsVolts(muxData,adcData,"35"))
				setDataForLogging("PS3I",@sharedMem.getPsCurrent(muxData,eiPs,nil,nil))
				setDataForLogging("PS4V",@sharedMem.getPsVolts(muxData,adcData,"36"))
				setDataForLogging("PS4I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS2"))
				setDataForLogging("PS5V",@sharedMem.getPsVolts(muxData,adcData,"37"))
				setDataForLogging("PS5I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS5"))
				setDataForLogging("PS6V",@sharedMem.getPsVolts(muxData,adcData,"38"))
				setDataForLogging("PS6I",@sharedMem.getPsCurrent(muxData,eiPs,"24",nil))
				setDataForLogging("PS7V",@sharedMem.getPsVolts(muxData,adcData,"39"))
				setDataForLogging("PS7I",@sharedMem.getPsCurrent(muxData,eiPs,nil,"IPS7"))
				setDataForLogging("PS8V",@sharedMem.getPsVolts(muxData,adcData,"40"))
				setDataForLogging("PS8I",@sharedMem.getPsCurrent(muxData,eiPs,"25",nil))
				setDataForLogging("PS9V",@sharedMem.getPsVolts(muxData,adcData,"41"))
				setDataForLogging("PS9I",@sharedMem.getPsCurrent(muxData,eiPs,"26",nil))
				setDataForLogging("PS10V",@sharedMem.getPsVolts(muxData,adcData,"42"))
				setDataForLogging("PS10I",@sharedMem.getPsCurrent(muxData,eiPs,"27",nil))
				setDataForLogging("P5V",@sharedMem.PNPCellSub(slotOwnerParam,"43"))
				setDataForLogging("N5V",@sharedMem.PNPCellSub(slotOwnerParam,"44"))
				setDataForLogging("P12V",@sharedMem.PNPCellSub(slotOwnerParam,"45"))
				setDataForLogging("5V",@sharedMem.getPsVolts(muxData,adcData,"48"))
				setDataForLogging("5I",@sharedMem.getPsCurrent(muxData,eiPs,"29",nil))
				setDataForLogging("12V",@sharedMem.getPsVolts(muxData,adcData,"46"))
				setDataForLogging("12I",@sharedMem.getPsCurrent(muxData,eiPs,"30",nil))
				setDataForLogging("24V",@sharedMem.getPsVolts(muxData,adcData,"47"))
				setDataForLogging("24I",@sharedMem.getPsCurrent(muxData,eiPs,"31",nil))

				if adcData.nil? == false
					if adcData[SharedLib::SlotTemp1.to_s].nil? == false
						temp1Param = (adcData[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(3)
					else
						temp1Param = "-"
					end
	
					if adcData[SharedLib::SlotTemp2.to_s].nil? == false
						temp2Param = (adcData[SharedLib::SlotTemp2.to_s].to_f/1000.0).round(3)
					else
						temp2Param = "-"
					end
				else
					temp1Param = "-"
					temp2Param = "-"
				end
			
				setDataForLogging("SlotTemp1",temp1Param)
				setDataForLogging("SlotTemp2",temp2Param)

				toBeWritten = ""
				if @newLog[slotOwnerParam] == true
					# puts "logging for #{slotOwnerParam}.  The file [#{SharedMemory::StepsLogRecordsPath}/#{getLogFileName(slotOwnerParam)}] is NOT present.  Attempting to create.  #{Time.new.inspect}"
					@arrDataLog.each { 
						|hashIndex| 
						if toBeWritten.length>0
							toBeWritten += "|"
						end
						toBeWritten += hashIndex
					}
					# puts "file = '#{SharedMemory::StepsLogRecordsPath}/#{@sharedMem.getLogFileName(slotOwnerParam)}' toBeWritten = '#{toBeWritten}'"
					filePresent = `cd #{SharedMemory::StepsLogRecordsPath}; echo \"#{toBeWritten}\" >> #{@sharedMem.getLogFileName(slotOwnerParam)}`
					@newLog[slotOwnerParam] = false
					@lastLog[slotOwnerParam] = logInterval5Min+Time.new.to_i				
				else
					# puts "logging for #{slotOwnerParam}.  The file is present #{Time.new.inspect}"
					@arrDataLog.each { 
						|hashIndex| 
						if toBeWritten.length>0
							toBeWritten += "|"
						end
						toBeWritten += @hashForLog[hashIndex].to_s
					}					
					filePresent = `cd #{SharedMemory::StepsLogRecordsPath}; echo \"#{toBeWritten}\" >> #{@sharedMem.getLogFileName(slotOwnerParam)}`
				end

				@lastLog[slotOwnerParam] += logInterval5Min
				
=begin				
				puts "#{Time.now.inspect} toBeWritten='#{toBeWritten}'"
				if slotOwnerParam == "SLOT2"
					@arrDataLog.each { 
						|hashIndex| 
						if @hashForLog[hashIndex] != "-"
							puts "listing hashIndex slotOwnerParam='#{slotOwnerParam}' #{hashIndex} ='#{@hashForLog[hashIndex]}'"
						end
					}
				end
=end

			else
				if @newLog[slotOwnerParam] == false && @sharedMem.GetDispAllStepsDone_YesNo(slotOwnerParam) == SharedLib::Yes
					@newLog[slotOwnerParam] = true
				end
			end
		end
	end
	
	def runLogger
		time = Time.now.to_f+1
		while true
			logData("SLOT1")	
			logData("SLOT2")		
			logData("SLOT3")			
			sleepTime = time-Time.now.to_f
			if sleepTime>0
				sleep(sleepTime)
			end
		end
	end
	
end

dl = DataLogger.new
dl.runLogger

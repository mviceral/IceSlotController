# Code to look at:
# "BBB PcListener is down.  Need to handle this in production code level."
# 
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'json'
require 'rest_client'
require_relative '../lib/SharedLib'
require_relative '../lib/DRbSharedMemory/LibServer'
require_relative '../lib/SharedMemory'
require 'pp' # Pretty print to see the hash values.

require 'drb/drb'
SERVER_URI="druby://localhost:8787"

class UserInterface
	SERVER_URI="druby://localhost:8787"
	BbbPcListener = 'http://192.168.7.2'
	# BbbPcListener = 'http://192.168.1.211'
	LinuxBoxPcListener = "localhost"
	PcListener = BbbPcListener # Chose which ethernet address the PcListener is sitting on.
	#
	# Template flags
	#
	PretestSiteIdentification = "Pretest (site identification)"
	
	StepConfigFileFolder = "../steps\ config\ file\ repository"

	#
	# Settings file constants
	#
	IndexCol ="IndexCol"

	#
	# Constants for what is to be displayed.
	#
	BlankFileName = "-----------"
	
	#
	# Button Labels.
	#
	Load = "Load"
	Run = "Run"
	Stop = "Stop"
	Clear = "Clear"
	
	#
	# Accessor for the button image like Stop, Play, Load(Folder), Eject
	#
	BtnDisplayImg = "BtnDisplayImg"
	LoadImg = "LoadImg.gif"
	
	#
	# Column name parameters
	#
	Unit = "Unit"
	NomSet = "NomSet"
	TripMin = "TripMin"
	TripMax = "TripMax"
	FlagTolP = "FlagTolP"
	FlagTolN = "FlagTolN"
	EnableBit = "EnableBit"
	IdleState = "IdleState"
	LoadState = "LoadState"
	StartState = "StartState"
	RunState = "RunState"
	StopState = "StopState"
	ClearState = "ClearState"
	FileName = "FileName"
	attr_accessor :slotProperties
	attr_accessor :upLoadConfigErrorName
	attr_accessor :upLoadConfigErrorRow
	attr_accessor :upLoadConfigErrorIndex
	attr_accessor :upLoadConfigErrorInFile
	attr_accessor :configFileType
	attr_accessor :upLoadConfigErrorCol
	attr_accessor :upLoadConfigErrorColType
	attr_accessor :upLoadConfigErrorValue
	attr_accessor :knownConfigRowNames
	attr_accessor :upLoadConfigErrorGeneral
	attr_accessor :upLoadConfigGoodUpload
	attr_accessor :redirectWithError
	attr_accessor :stepName
	attr_accessor :redirectErrorFaultyPsConfig	
	
	def clearErrorSlot(slotOwnerParam)
		# puts "clearErrorSlot(slotOwnerParam) got called. slotOwnerParam='#{slotOwnerParam}' SharedLib::ErrorMsg='#{SharedLib::ErrorMsg}'"
		ds = @sharedMem.lockMemory("#{__LINE__}-#{__FILE__}")
		ds[SharedLib::PC][slotOwnerParam][SharedLib::ErrorMsg] = nil
		@sharedMem.writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
	end

	def getBoardIp(slotParam, fromParam)
		if @slotToIp.nil? # || @slotToIp[slotParam].nil? ||@slotToIp[slotParam].length == 0
			@slotToIp = Hash.new
			@slotToIp[SharedLib::SLOT1] = "192.168.7.2"
			#@slotToIp[SharedLib::SLOT2] = "192.168.7.2"
			#@slotToIp[SLOT3] = ""
		end
		# puts "slotParam='#{slotParam}' @slotToIp='#{@slotToIp}' fromParam=#{fromParam} #{__LINE__}-#{__FILE__}"
		return @slotToIp[slotParam]
	end
	
	def redirectErrorFaultyPsConfig
		@redirectErrorFaultyPsConfig
	end
	
	def dirFileRepository
		return StepConfigFileFolder
	end

	def redirectWithError
		@redirectWithError
	end
	
	def setConfigFileName(fileNameParam)
		getSlotProperties()[FileName] = fileNameParam
	end
	
	def mustBeBoolean(configFileName,ctParam,config,itemNameParam)
		#
		# returns true if the 
		#
		indexOfStepNameFromCt = ctParam - 5
		ct = ctParam #9 "Auto Restart"
		while ct < config.length do
			stepName = config[ct-indexOfStepNameFromCt].split(",")[2].strip # Get the row data for the step file name.
			stepTime = config[ct].split(",")[4].strip
			if (stepTime=="1" || stepTime == "0") == false
				#
				# Given number is not good
				#
				@redirectWithError += "&ErrInFile="
				@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
				error = "Step File '#{configFileName}' - '#{itemNameParam}' '#{stepTime}' on line "
				error += "'#{ct+1}' must be a boolean (1 or 0)."
				@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
				return false
			else
				slotConfigStep = getSlotConfigStep(stepName)
				slotConfigStep[itemNameParam] = stepTime
			end
			ct += 11
			# End of 'while ct < config.length do' 
		end
		return true
	end
	
	def mustBeNumber(configFileName,ctParam,config,itemNameParam)
		#
		# returns true if the 
		#
		indexOfStepName = ctParam - 5
		ct = ctParam
		while ct < config.length do
			colName = config[ct-indexOfStepName].split(",")[1].strip # Get the row data for the step file name.
			stepName = config[ct-indexOfStepName].split(",")[2].strip # Get the row data for the step file name.
			# pause("colName = #{colName}, stepName='#{stepName}'","#{__LINE__}-#{__FILE__}")
			if colName == "Step Name"
				stepName = config[ct-indexOfStepName].split(",")[2].strip # Get the row data for the step file name.
				stepTime = config[ct].split(",")[4].strip
				if SharedLib.is_a_number?(stepTime) == false
					#
					# Given number is not good
					#
					@redirectWithError += "&ErrInFile="
					@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
					error = "Step File '#{configFileName}' - '#{itemNameParam}' '#{stepTime}' on line "
					error += "'#{ct+1}' must be a number."
					puts "A error =>#{error}<= @#{__LINE__}-#{__FILE__}"
					@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
					puts "B @redirectWithError =>#{@redirectWithError}<= @#{__LINE__}-#{__FILE__}"
					return false
				else				
					slotConfigStep = getSlotConfigStep(stepName)
					slotConfigStep[itemNameParam] = stepTime
					# puts "\n\n\nCheck below #{__LINE__}-#{__FILE__}"
					# puts "stepName='#{stepName}'"
					# puts "stepTime='#{stepTime}'"
					# puts "itemNameParam='#{itemNameParam}'"
				end
			end				
			ct += 11
			# End of 'while ct < config.length do' 
		end
		return true
	end
	
	def getMaxColCt(configTemplateRows)
		maxColCt = 0
		rowCt = 0
		while rowCt<configTemplateRows.length do
			columns = configTemplateRows[rowCt].split(",")
			colCt = 0
			while colCt<columns.length do
				colCt += 1
			end
			if maxColCt < colCt
				maxColCt = colCt
			end
			rowCt += 1
		end
		return maxColCt			
	end
	
	def convertToTable(configTemplateRows,maxColCt) 
		tbr = "" # tbr - to be returned
		tbr += "			
				<table width=\"100%\">
					<tr>
						<td align=\"center\">
							<center>
							<table style=\"border-collapse: collapse;\">"
							rowCt = 0
							while rowCt<configTemplateRows.length do
								tbr += "<tr style=\"border: 1px solid black;\">"
								columns = configTemplateRows[rowCt].split(",")
								colCt = 0
								while colCt<columns.length do
									tbr += "<td style=\"border: 1px solid black;\"><font size=\"1\">"+columns[colCt]
									tbr += "</font></td>"		
									colCt += 1
								end
					
								while colCt<maxColCt do
									tbr += "<td style=\"border: 1px solid black;\"><font size=\"1\">&nbsp;</font></td>"		
									colCt += 1
								end
					
								tbr += "</tr>"
								rowCt += 1
							end			
						tbr += "
							</table>
							</center>
						</td>
					</tr>
				</table>
			"
	end
	
	def upLoadConfigGoodUpload
		@upLoadConfigGoodUpload
	end
	
	def slotOwnerThe
		@slotOwnerThe
	end
	
	def setSlotOwner(slotOwnerParam)
		@slotOwnerThe = slotOwnerParam
		@sharedMem.SetDispSlotOwner(slotOwnerParam)
	end

	def getSlotOwner
		if @slotOwnerThe.nil? || @slotOwnerThe == ""
			redirect "../"
		end
		return @slotOwnerThe
	end
	
	def clearError
		@upLoadConfigErrorName = ""
		@upLoadConfigErrorRow = ""
		@upLoadConfigErrorIndex = ""
		@upLoadConfigErrorCol = ""
		@upLoadConfigErrorColType = ""
		@upLoadConfigErrorValue = ""
		@upLoadConfigErrorGeneral = ""
		@upLoadConfigErrorInFile = ""
	end
	
	def upLoadConfigErrorGeneral
		@upLoadConfigErrorGeneral
	end
	
	def stepName
		@stepName
	end
	
	def configFileType
		if (@configFileType == "TempSetTemplate" ||
			 @configFileType == "PSSeqFileTemplate" )
		end
		@configFileType
	end
	
	def upLoadConfigErrorInFile
		@upLoadConfigErrorInFile
	end
		
	def upLoadConfigErrorIndex
		@upLoadConfigErrorIndex
	end
	
	def upLoadConfigErrorColType
		@upLoadConfigErrorColType
	end
	
	def upLoadConfigErrorValue
		@upLoadConfigErrorValue
	end

	
	def upLoadConfigErrorRow
		@upLoadConfigErrorRow
	end
	
	def upLoadConfigErrorCol
		@upLoadConfigErrorCol
	end
	
	def upLoadConfigErrorName
		@upLoadConfigErrorName
	end
	
	def GetDurationLeft(slotLabel2Param)
		# If the button state is Stop, subtract the total time between now and TimeOfRun, then 
		if @sharedMem.GetDispStepTimeLeft(slotLabel2Param).nil? == false
			totMinsInQueue = @sharedMem.GetDispTotalTimeOfStepsInQueue(slotLabel2Param).to_i
			totMinsInQueue += @sharedMem.GetDispStepTimeLeft(slotLabel2Param).to_i
			totalMins = (totMinsInQueue)/60
			totalSec = totMinsInQueue-60*totalMins
			totalSec = totalSec.to_s
			if totalSec.length<2
				totalSec = "0"+totalSec
			end

			totalMins = totalMins.to_s
			if totalMins.length<2
				totalMins = "0"+totalMins
			end
			return "#{totalMins}:#{totalSec} (mm:ss)"
		else 
		end
	end 

	def make2Digits(paramDigit)
		if paramDigit.length < 2
			paramDigit = "0"+paramDigit
		end
		return paramDigit
	end
	
	def Clear
		return Clear
	end

	def Stop
		return Stop
	end
	
	def Run
		return Run
	end
	
	def Load
		return Load
	end 
	
	def slotProperties
		if @slotProperties.nil?
			@slotProperties = Hash.new
		end
		@slotProperties
	end
	
	def getSlotProperties()
		if slotProperties[getSlotOwner()].nil?
			slotProperties[getSlotOwner()] = Hash.new
		end
		return slotProperties[getSlotOwner()]
	end

	def getButtonImage()
		if getSlotProperties()[BtnDisplayImg].nil?
			getSlotProperties()[BtnDisplayImg] = LoadImg
		end
		return getSlotProperties()[BtnDisplayImg]
	end
	
	def getButtonDisplay(slotLabel2Param,fromParam)
		# puts "getButtonDisplay() got called."
		tbr = "" # To be returned
		configFileName = @sharedMem.GetDispConfigurationFileName(slotLabel2Param)
		# @sharedMem.SetDispSlotOwner(slotLabelParam)
		# puts "slotLabelParam=#{slotLabelParam}"
		# puts "@sharedMem.GetDispSlotOwner()=#{@sharedMem.GetDispSlotOwner()}"
		# puts "configFileName.nil? = #{configFileName.nil?}"
		# puts "configFileName = #{configFileName}"
		# puts "@sharedMem.GetDispBbbMode(slotLabel2Param) = #{@sharedMem.GetDispBbbMode(slotLabel2Param)}"
		if configFileName.nil? || configFileName.length == 0
			return Load
		end
		
		if @sharedMem.GetDispAllStepsDone_YesNo(slotLabel2Param) == SharedLib::Yes && 
			configFileName.nil? == false &&
			configFileName.length > 0
			return Clear
		end
		
		if @sharedMem.GetDispAllStepsDone_YesNo(slotLabel2Param) == SharedLib::No && 
			configFileName.nil? == false &&
			configFileName.length > 0
			if @sharedMem.GetDispBbbMode(slotLabel2Param) == SharedLib::InRunMode			
				return Stop
			else
				return Run
			end
		elsif @sharedMem.GetDispAllStepsDone_YesNo(slotLabel2Param) == SharedLib::No &&
			@sharedMem.GetDispBbbMode(slotLabel2Param) == SharedLib::InStopMode
			return Run
		end

		return Load
	end
	
	def setToLoadMode(slotOwnerParam)
		begin
			puts "Clearing board IP=#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")} #{__LINE__}-#{__FILE__}"
			hash = Hash.new
			hash[SharedLib::SlotOwner] = slotOwnerParam
			slotData = hash.to_json
			@response = 			
		    RestClient.post "#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::ClearConfigFromPc}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
			@sharedMem.SetDispButton(slotOwnerParam,"Clearing")
			rescue
			@redirectWithError = "/TopBtnPressed?slot=#{slotOwnerParam}&BtnState=#{Load}"
			#@redirectWithError += "&ErrGeneral=bbbDown"
			@redirectWithError += "&ErrGeneral=ABDC"
			# gets
			return false
		end
		# hash1 = JSON.parse(@response)
		# hash2 = JSON.parse(hash1["bbbResponding"])
		# PP.pp(hash2)
		# puts "Checking hash2 content.  #{__LINE__}-#{__FILE__}"
		# gets
  		# @sharedMem.SetDataBoardToPc(hash2)
		# puts "C Checking.  #{__LINE__}-#{__FILE__}"
	end

	def writeToSettingsLog(toBeWritten,settingsFileName)
		`cd #{SharedMemory::StepsLogRecordsPath}; echo \"#{toBeWritten}\" >> #{settingsFileName}`
	end

	def setBbbConfigUpload(slotOwnerParam)
		slotProperties[slotOwnerParam][SharedLib::ConfigDateUpload] = Time.now.to_f
		slotProperties[slotOwnerParam][SharedLib::SlotOwner] = slotOwnerParam
		slotData = slotProperties[slotOwnerParam].to_json

		fileName = getSlotProperties()["FileName"]
		configDateUpload = getSlotProperties()[SharedLib::ConfigDateUpload]
		genFileName = SharedLib.getFileNameRecord(fileName,configDateUpload,slotOwnerParam)
		settingsFileName =  genFileName+".log"
		recipeStepFile = "../steps config file repository/#{fileName}"
		recipeLastModified = File.mtime(recipeStepFile)
		
		writeToSettingsLog("Program: #{fileName}, Last modified: #{recipeLastModified}",settingsFileName)
		
		# Get the oven ID
		# Read the content of the file "Mosys ICEngInc.config" file to get the needed information...
		config = Array.new
		File.open("../Mosys ICEngInc.config", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end			
		end
		
		# Parse each lines and mind the information we need for the report.
		ct = 0
		while ct < config.length 
			colContent = config[ct].split(":")
			if colContent[0] == "Oven ID"
				oven = colContent[1].chomp
				oven = oven.strip
			elsif colContent[0] == "#{slotOwnerParam} BIB#"
				bibID = colContent[1].chomp
				bibID = bibID.strip
			end
			ct += 1
		end
		writeToSettingsLog("System: #{oven}, Slot: #{slotOwnerParam}",settingsFileName)
		writeToSettingsLog("BIB#: #{bibID}",settingsFileName)

=begin
		psItems = ["VPS0","IPS0","VPS1","IPS1","VPS2","IPS2","VPS3","IPS3","VPS4","IPS4","VPS5","IPS5","VPS6","IPS6","VPS7","IPS7","VPS8","IPS8","VPS9","IPS9","VPS10","IPS10","IDUT"]
		ct = 0
		getSlotProperties()["LastPrintedStepNum"] = 0
		getSlotProperties()["LastPrintedStepName"] = ""
		getSlotProperties().each do |key, array|
			puts "key='#{key}' array=#{array}\n\n\n"			
			if ct == 1
				# This is the first step.
			end
			if key == "Steps"
				ct = 0
				array.each do |key2, array2|
					if ct == 0
						# We're working on the pretest.
						array2.each do  |key3, array3|
							array3.each do |key4, array4|
								if psItems.include? key4
									if key4 == "VPS0"
									end
								end
							end
						end
					end
					ct += 1
				end
			end
			ct += 1
		end
=end

		# PP.pp(getSlotProperties())
		# puts "About to send to the Board. #{__LINE__}-#{__FILE__}"
		# exit
		begin
			@response = 
		    RestClient.post "#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}:8000/v1/pclistener/", { PcToBbbCmd:"#{SharedLib::LoadConfigFromPc}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
			puts "#{__LINE__}-#{__FILE__} @response=#{@response}"
			@sharedMem.SetDispButton(slotOwnerParam,"Loading")			
			# hash1 = JSON.parse(@response)
			# puts "check A #{__LINE__}-#{__FILE__}"
			# hash2 = JSON.parse(hash1["bbbResponding"])
			# puts "check B #{__LINE__}-#{__FILE__}"
			# @sharedMem.SetDataBoardToPc(hash2)
			# puts "check C #{__LINE__}-#{__FILE__}"
			return true
			rescue
			puts "No response.#{__LINE__}-#{__FILE__} @response=#{@response}"
			@redirectWithError = "/TopBtnPressed?slot=#{slotOwnerParam}&BtnState=#{Load}"
			@redirectWithError += "&ErrGeneral=bbbDown"
			#@redirectWithError += "&ErrGeneral=EFGH"
			return false
		end
	end

	def cellWidth
		return 95
	end

	def initialize
		@slotToIp = nil		
		DRb.start_service
		@sharedMemService = DRbObject.new_with_uri(SERVER_URI)
		@sharedMem = SharedMemory.new
		# end of 'def initialize'
	end

	def SlotCell(slotLabel2Param)
		adcInput = @sharedMem.GetDispAdcInput(slotLabel2Param)
		if adcInput.nil? == false
			if adcInput[SharedLib::SlotTemp1.to_s].nil? == false
				temp1Param = (adcInput[SharedLib::SlotTemp1.to_s].to_f/1000.0).round(3)
			else
				temp1Param = "---"
			end
			
			if adcInput[SharedLib::SlotTemp2.to_s].nil? == false
				temp2Param = (adcInput[SharedLib::SlotTemp2.to_s].to_f/1000.0).round(3)
			else
				temp2Param = "---"
			end
		else
			temp1Param = "---"
			temp2Param = "---"
		end

		bkcolor = setBkColor(slotLabel2Param,"#ffaa77")
		toBeReturned = "<table bgcolor=\"#{bkcolor}\" width=\"#{cellWidth}\">"
		toBeReturned += "<tr><td><font size=\"1\">SLOT</font></td></tr>"
		toBeReturned += "	<tr>
							<td>
								<font size=\"1\">TEMP1</font>
							</td>
							<td>
								<font size=\"1\">#{temp1Param}C</font>
							</td>
						</tr>"
		toBeReturned += "<tr><td><font size=\"1\">TEMP2</font></td><td><font size=\"1\">#{temp2Param}C</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end
	
	def PNPCell(slotLabel2Param,posVoltParam, negVoltParam, largeVoltParam)
		posVolt = @sharedMem.PNPCellSub(slotLabel2Param,posVoltParam)
		negVolt = @sharedMem.PNPCellSub(slotLabel2Param,negVoltParam)
		largeVolt = @sharedMem.PNPCellSub(slotLabel2Param,largeVoltParam)
		bkcolor = setBkColor(slotLabel2Param,"#6699aa")
		toBeReturned = "<table bgcolor=\"#{bkcolor}\" width=\"#{cellWidth}\">"
		toBeReturned += "<tr><td><font size=\"1\">P5V</font></td><td><font size=\"1\">#{posVolt}V</font></td></tr>"
		toBeReturned += "<tr><td><font size=\"1\">N5V</font></td><td><font size=\"1\">#{negVolt}V</font></td></tr>"
		toBeReturned += "<tr><td><font size=\"1\">P12V</font></td><td><font size=\"1\">#{largeVolt}V</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def setBkColor(slotLabel2Param,defColorParam)
		configurationFileName = @sharedMem.GetDispConfigurationFileName(slotLabel2Param)
		if configurationFileName.nil? == false &&  configurationFileName.length > 0
			if @sharedMem.GetDispAllStepsDone_YesNo(slotLabel2Param) == SharedLib::Yes
				cellColor = "#04B404"
			else
				# puts "printing GREEN (#{@sharedMem.GetDispConfigurationFileName(slotLabel2Param).length})- #{__LINE__} #{__FILE__}"
				cellColor = defColorParam
			end
		else
			# puts "printing GRAY - #{__LINE__} #{__FILE__}"
			cellColor = "#cccccc"			
		end
	end

	def PsCell(slotLabel2Param,labelParam,rawDataParam, iIndexParam)
		muxData = @sharedMem.GetDispMuxData(slotLabel2Param)
		adcData = @sharedMem.GetDispAdcInput(slotLabel2Param)
		rawDataParam = @sharedMem.getPsVolts(muxData,adcData,rawDataParam)

		eiPs = @sharedMem.GetDispEips(slotLabel2Param)
		current = @sharedMem.getPsCurrent(muxData,eiPs,iIndexParam,labelParam)

		cellColor = setBkColor(slotLabel2Param,"#6699aa")
		toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
		toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
		toBeReturned += "<tr>"
		if labelParam == "S8"
			style = "style=\"border:1px solid black;background-color:#ff0000\""
		else
			style = ""
		end
		toBeReturned += "	<td #{style} >
												<font size=\"1\">Voltage</font>
											</td>
											<td #{style} >
												<font size=\"1\">#{rawDataParam}V</font>
											</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">#{current}A</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def DutCell(slotLabel2Param, labelParam,rawDataParam)
		muxData = @sharedMem.GetDispMuxData(slotLabel2Param)
		current = SharedLib::getCurrentDutDisplay(muxData,rawDataParam)

		if @sharedMem.GetDispTcu(slotLabel2Param).nil? == false && @sharedMem.GetDispTcu(slotLabel2Param)["#{rawDataParam}"].nil? == false
			tcuData = @sharedMem.GetDispTcu(slotLabel2Param)["#{rawDataParam}"]
		else
			tcuData = "---"
		end
		cellColor = setBkColor(slotLabel2Param,"#99bb11")
		if tcuData == "---"
			cellColor = "#B6B6B4"
		else
			temperature = SharedLib.make5point2Format(tcuData.split(',')[2])
		end
		# puts "rawDataParam=#{rawDataParam}, tcuData=#{tcuData} #{__LINE__}-#{__FILE__}"
		
		toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
		toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
		toBeReturned += "<tr>"
		if labelParam == "S8"
			bgcolor = "bgcolor=\"#ff0000\""
		else
			bgcolor = ""
		end
		toBeReturned += "	
			<td #{bgcolor} >
				<font size=\"1\">Temp</font>
			</td>
			<td #{bgcolor} >
				<font size=\"1\">#{temperature} C</font>
			</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">#{current} A</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def getRows(dirParam)
		repoDir = StepConfigFileFolder
		tbr = "" # tbr - to be returned
		files = dirParam
		fileIndex = 0;
		totalColumns = 0
		rowItems = ""
		while fileIndex< files.length
			rowItems += "<td style=\"border: 1px solid black;\">&nbsp;<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"window.location='../ViewFile?File=#{files[fileIndex]}'\" />
							View
							</button>&nbsp;<font size=\"1\">"+files[fileIndex]+"</font>&nbsp;</td>"		
			totalColumns += 1
			if totalColumns >= 4
				tbr += "<tr>"+rowItems+"</tr>"
				rowItems = ""
				totalColumns = 0
			end
			fileIndex += 1
		end
		
		if totalColumns != 0
			while (totalColumns >= 4) == false
				rowItems += "<td style=\"border: 1px solid black;\">&nbsp;<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"\"  DISABLED/>
							View
							</button>&nbsp;---&nbsp;</td>"		
				totalColumns += 1
			end
		end
		
		if rowItems.length > 0
			tbr += "<tr>"+rowItems+"</tr>"
		end
		return tbr
	end
	
	def GetSlotFileName(slotParam)	
		if @sharedMem.GetDispConfigurationFileName(slotParam).nil? ||
				@sharedMem.GetDispConfigurationFileName(slotParam).length == 0
			return BlankFileName
		else
			return @sharedMem.GetDispConfigurationFileName(slotParam)
		end
	end
	
	def getStepCompletion(slotParam)
		if @sharedMem.GetDispConfigurationFileName(slotParam).nil? ||
				@sharedMem.GetDispConfigurationFileName(slotParam).length == 0
			return BlankFileName
		else
			d = Time.now
			d += @sharedMem.GetDispStepTimeLeft(slotParam).to_i 
			
			month = d.month.to_s # make2Digits(d.month.to_s)
			day = d.day.to_s # make2Digits(d.day.to_s)
			year = d.year.to_s
			hour = make2Digits(d.hour.to_s)
			min = make2Digits(d.min.to_s)
			sec = make2Digits(d.sec.to_s)
			return month+"/"+day+"/"+year+" "+hour+":"+min # +":"+sec
		end
	end
	
	def removeWhiteSpace(slotLabelParam)
		return slotLabelParam.delete(' ')
	end
	
	def GetSlotDisplay(slotLabelParam,slotLabel2Param)
		setSlotOwner(slotLabel2Param)
		getSlotDisplay_ToBeReturned = ""
		getSlotDisplay_ToBeReturned += 	
		"<table style=\"border-collapse : collapse; border : 1px solid black;\"  bgcolor=\"#000000\">"
		getSlotDisplay_ToBeReturned += 	"<tr>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S20","20")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S16","16")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S12","12")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S8","8")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S4","4")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S0","0")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS0","32",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS4","36",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS8","40","25")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"5V","48","29")+"</td>"
		getSlotDisplay_ToBeReturned += 	"</tr>"
		getSlotDisplay_ToBeReturned += 	"<tr>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S21","21")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S17","17")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S13","13")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S9","9")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S5","5")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S1","1")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS1","33",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS5","37",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS9","41","26")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"12V","46","30")+"</td>"
		getSlotDisplay_ToBeReturned += 	"</tr>"
		getSlotDisplay_ToBeReturned += 	"<tr>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S22","22")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S18","18")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S14","14")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S10","10")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S6","6")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S2","2")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS2","34",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS6","38","24")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS10","42","27")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"24V","47","31")+"</td>"
		getSlotDisplay_ToBeReturned += 	"</tr>"
		getSlotDisplay_ToBeReturned += 	"<tr>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S23","23")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S19","19")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S15","15")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S11","11")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S7","7")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell(slotLabel2Param,"S3","3")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS3","35",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell(slotLabel2Param,"PS7","39",nil)+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : 
			collapse; border : 1px solid black;\">"+PNPCell(slotLabel2Param,"43","44","45")+"</td>"
		getSlotDisplay_ToBeReturned += 	
		"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+SlotCell(slotLabel2Param)+"</td>"
		getSlotDisplay_ToBeReturned += 	"</tr>"
		getSlotDisplay_ToBeReturned += 	"</table>"
		errMsg = @sharedMem.getDispErrorMsg(slotLabel2Param)
		topTable = "
			<table>
				<tr><td></td><td/></tr>
				<tr><td></td><td/></tr>
				<tr>
					<td>
						<table>
							<tr>
								<td nowrap>
									<font size=\"3\"/>#{slotLabelParam}
								</td>
								<td>&nbsp;</td>
								<td style=\"border:1px solid black; border-collapse:collapse; width: 95%;\">
									<font size=\"1\" color=\"red\"/>#{errMsg}
								</td>
								<td>
									<button onclick=\"window.location='/AckError?slot=#{slotLabel2Param}'\" style=\"height:20px;
									width:50px; font-size:10px\" />Ok</button>
								</td>
							</tr>
						</table>
					</td>
					<td valign=\"top\" rowspan=\"2\">
				 		<table>"
		if @sharedMem.GetDispWaitTempMsg(slotLabel2Param).nil? == false
			stepNum = @sharedMem.GetDispStepNumber(slotLabel2Param)
			topTable += "								
				 			<tr><td align=\"center\"><font size=\"1.75\"/>Step '#{stepNum}' Waiting Temp Tolerance</td></tr>
				 			<tr>
				 				<td align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">"
			disp = @sharedMem.GetDispWaitTempMsg(slotLabel2Param)
			topTable += "		#{disp}				 							
				 					</font>
				 				</td>
				 			</tr>"
		elsif @sharedMem.GetDispAllStepsDone_YesNo(slotLabel2Param) == SharedLib::Yes &&
				@sharedMem.GetDispConfigurationFileName(slotLabel2Param).nil? == false &&
				@sharedMem.GetDispConfigurationFileName(slotLabel2Param).length > 0
			topTable += "
				 			<tr><td align=\"center\"><font size=\"1.75\"/>ALL STEPS COMPLETE</td></tr>
				 			<tr>
				 				<td align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">
				 							<label 
				 								id=\"stepCompletion_#{slotLabel2Param}\">
				 									Date: "
				 									time = Time.at(@sharedMem.GetDispAllStepsCompletedAt(slotLabel2Param).to_i)				 									
			topTable += "
				 									#{time.strftime("%m/%d/%Y %H:%M:%S")}
				 							</label>
				 					</font>
				 				</td>
				 			</tr>"
		else
			if @sharedMem.GetDispConfigurationFileName(slotLabel2Param).nil? ||
				@sharedMem.GetDispConfigurationFileName(slotLabel2Param).length == 0
				stepNum = ""
			else
				stepNum = @sharedMem.GetDispStepNumber(slotLabel2Param)
			end
			topTable += "
				 			<tr><td align=\"center\"><font size=\"1.75\"/>STEP '#{stepNum}' COMPLETION AT</td></tr>
				 			<tr>
				 				<td align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">
				 							<label 
				 								id=\"stepCompletion_#{slotLabel2Param}\">
				 									#{getStepCompletion(slotLabel2Param)}
				 							</label>
				 					</font>
				 				</td>
				 			</tr>"
		end
		btnState = getButtonDisplay(slotLabel2Param,"#{__LINE__}-#{__FILE__}")
		topTable += "
				 			<tr>
				 				<td>
				 					<hr>
				 				</td>
				 			</tr>
				 			<tr>
				 				<td align = \"center\">
				 					<button 
										onclick=\"window.location='/TopBtnPressed?slot=#{slotLabel2Param}&BtnState=#{btnState}'\"
										type=\"button\" 
				 						style=\"width:100;height:25\" 
				 						id=\"btn_#{slotLabel2Param}\" "
		if getBoardIp(slotLabel2Param,"#{__LINE__}-#{__FILE__}").nil?
			disabled = "disabled"
		else
			disabled = ""
		end
		btnStateDisp = @sharedMem.GetDispButton(slotLabel2Param)
		toDisplay = getButtonDisplay(slotLabel2Param,"#{__LINE__}-#{__FILE__}")
		# puts "toDisplay=#{toDisplay} #{__LINE__}-#{__FILE__}"
		# puts "btnStateDisp=#{btnStateDisp} #{__LINE__}-#{__FILE__}"
		if btnStateDisp.nil? == false 
			if btnStateDisp != SharedLib::NormalButtonDisplay
				toDisplay = btnStateDisp
			end
			if btnStateDisp == "Seq Up"
				toDisplay = btnStateDisp
			elsif  btnStateDisp == "Clearing"
				toDisplay = btnStateDisp
			elsif  btnStateDisp == "Seq Down"
				toDisplay = btnStateDisp
			elsif  btnStateDisp == "Loading"
				toDisplay = btnStateDisp
			end
		end
		topTable += "#{disabled}
				 						>
				 							#{toDisplay}
				 					</button>
				 				</td>
				 			</tr>
							<tr>
								<td align=\"left\">
										<font size=\"1\">Step File Name:</font>
								</td>
							</tr>
							<tr>
								<td>
									<center>"
		if @sharedMem.GetDispConfigurationFileName(slotLabel2Param).nil? || @sharedMem.GetDispConfigurationFileName(slotLabel2Param).length==0
			disp = BlankFileName
		else
			disp = @sharedMem.GetDispConfigurationFileName(slotLabel2Param)
		end
		topTable+="
									<font size=\"1.25\" style=\"font-style: italic;\">#{disp}</font>"
		if disp != BlankFileName
		topTable+= "	<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"window.location='../ViewFile?File=#{disp}'\" />
							View
									</button>"									
		end									

		topTable += "								
									</center>
								</td>
							</tr>"
		if @sharedMem.GetDispConfigurationFileName(slotLabel2Param).nil? == false && 
			@sharedMem.GetDispConfigurationFileName(slotLabel2Param).length > 0
			topTable += "								
				<tr>
					<td align=\"left\">
							<font size=\"1\">Total Steps Duration:</font>
					</td>
				</tr>
				<tr>
					<td align = \"center\">
						<font size=\"1.25\" style=\"font-style: italic;\">"
							min = @sharedMem.GetDispTotalStepDuration(slotLabel2Param).to_i/60
							sec = @sharedMem.GetDispTotalStepDuration(slotLabel2Param).to_i - (min*60)
							min = min.to_s
							sec = sec.to_s

							if min.length < 2
								min = "0"+min
							end
							
							if sec.length < 2
								sec = "0"+sec
							end
			topTable += "		#{min}:#{sec} (mm:ss)
						</font>								
					</td>
				</tr>"
		end							
		
		if @sharedMem.GetDispBbbMode(slotLabel2Param) == SharedLib::InRunMode && @sharedMem.GetDispConfigurationFileName(slotLabel2Param).nil? == false && @sharedMem.GetDispConfigurationFileName(slotLabel2Param).length > 0
			topTable += "								
					<tr>
						<td align=\"left\">
								<font size=\"1\">Total Duration Left:</font>
						</td>
					</tr>
					<tr>
						<td align = \"center\">
							<font
								size=\"1.25\" 
								style=\"font-style: italic;\"
							>
								<label 
									id=\"durationLeft_#{slotLabel2Param}\"
								>
									#{GetDurationLeft(slotLabel2Param)}
								</label>
							</font>
						</td>
					</tr>"
    end
							
					topTable += "								
							<tr>
								<td>
								</td>
							</tr>
				 			<tr>
				 				<td align=\"center\">"
				 				
				 				if getButtonDisplay(slotLabel2Param,"#{__LINE__}-#{__FILE__}") == Run	
btnStateDisp = @sharedMem.GetDispButton(slotLabel2Param)
# puts "btnStateDisp='#{btnStateDisp}' #{__LINE__}-#{__FILE__}"
toDisplay = Clear
if btnStateDisp.nil? == false 
	if btnStateDisp != "Clearing"
		# toDisplay = btnStateDisp
		topTable+=				 					
			"
		<button 
			onclick=\"window.location='/TopBtnPressed?slot=#{slotLabel2Param}&BtnState=Clear'\"
			type=\"button\" 
			style=\"width:100;height:25\" 
			id=\"btn_LoadStartStop\"
			>
				#{toDisplay}
		</button>"
	end
end
				 				end
				 				
					topTable+=				 					
				 					"
				 				</td>
				 			</tr>
				 		</table>
					</td>
				</tr>
				<tr>
					<td>"+getSlotDisplay_ToBeReturned+"</td>
				</tr>
				<tr><td></td></tr>			
				<tr><td></td></tr>
			</table>"
		return topTable
	end
	
	def display
		# Get a fresh data...
		@sharedMem.processRecDataFromPC(@sharedMemService.getSharedMem().getDataFromBoardToPc())
		displayForm =  "	
	<style>
	#slotA
	{
	border:1px solid black;
	border-collapse:collapse;
	}
	</style>
	
	<script type=\"text/javascript\">

	ct = 0;
	function updateBtnColor(SlotParam,ct) {
		var btn = document.getElementById(\"btn_\"+SlotParam);
		if (ct == 0)
			btn.style=\"background: #ffaa77 no-repeat left;\"
		if (ct == 1)
			btn.style=\"background: #ffaa00 no-repeat left;\"			
		if (ct == 2)
			btn.style=\"background: #ff0077 no-repeat left;\"			
		if (ct == 3)
			btn.style=\"background: #00aa77 no-repeat left;\"
	}
		
	function loadXMLDoc()
	{
		var xmlhttp;
		if (window.XMLHttpRequest)
		{
			// code for IE7+, Firefox, Chrome, Opera, Safari
			xmlhttp=new XMLHttpRequest();
		}
		else
		{
			// code for IE6, IE5
			xmlhttp=new ActiveXObject(\"Microsoft.XMLHTTP\");
		}

		xmlhttp.onreadystatechange=function()
		{
			if (xmlhttp.readyState==4 && xmlhttp.status==200)
			{
				document.getElementById(\"myDiv\").innerHTML=xmlhttp.responseText;
			}
		}	
		xmlhttp.open(\"POST\",\"../\",true);
		xmlhttp.send();
	}
	
	setInterval(function(){loadXMLDoc()},1000);  
	</script>

	<div id=\"myDiv\">
	
	<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
		<tr><td><center>"+GetSlotDisplay("SLOT 1","SLOT1")+"</center></td></tr>
		<tr><td><center>"+GetSlotDisplay("SLOT 2","SLOT2")+"</center></td></tr>
		<tr><td><center>"+GetSlotDisplay("SLOT 3","SLOT3")+"</center></td></tr>
	</table>"
		return displayForm
		# end of 'def display'
	end
	
	def getListOfFiles(path, extentionParam)
		puts "cd '#{path}'; ls -lt #{extentionParam} #{__LINE__}-#{__FILE__}"
		listOfFiles = `cd "#{path}"; ls -lt #{extentionParam}`
		fileRow = listOfFiles.split("\n")
		ct = 0
		while ct<fileRow.length
			fileItem= fileRow[ct].split(" ")
			# puts "'0'=#{fileItem[0]}, '1'=#{fileItem[1]}, '2'=#{fileItem[2]}, '3'=#{fileItem[3]}, '4'=#{fileItem[4]}, '5'=#{fileItem[5]}, '6'=#{fileItem[6]}, '7'=#{fileItem[7]}, '8'=#{fileItem[8]}"
			at = fileRow[ct].index(fileItem[7])+fileItem[7].length
			ct += fileRow.length
		end

		ct = 0
		tbr = Array.new # tbr - to be returned
		while ct<fileRow.length
			tbr.push("#{fileRow[ct][(at+1)..-1]}")
			# puts "#{(ct)} - #{fileRow[ct][at..-1]}"
			ct += 1
		end
		return tbr
	end
	
	def loadFile
		#
		# tbr - to be returned
		#
		tbr = "
		<html>
			<body>"
		tbr += "
						<font size=\"3\">"
		tbr += "Slot #{getSlotOwner()[getSlotOwner().length-1..-1]} Setup<br>Step Files</font><br>"
		#
		# Create a list of Test Files, and display them in a table.
		# 						
		repoDir = StepConfigFileFolder
		files = getListOfFiles("#{repoDir}","*.step")
		tbr += "<table style=\"border-collapse: collapse;	border: 1px solid black;\">"
		fileIndex = 0;
		totalColumns = 0
		rowItems = ""
		while fileIndex< files.length
			rowItems += "<td style=\"border: 1px solid black;\">&nbsp;<button 
										style=\"height:20px; width:50px; font-size:10px\" 							
										onclick=\"window.location='../TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}&File=#{SharedLib.makeUriFriendly(files[fileIndex])}'\" />
										Select
										</button><button 
										style=\"height:20px; width:50px; font-size:10px\" 							
										onclick=\"window.location='../ViewFile?File=#{files[fileIndex]}'\" />
										View
										</button>&nbsp;<font size=\"1\">"+files[fileIndex]+"</font>

							&nbsp;</td>"		
			totalColumns += 1
			if totalColumns >= 4
				tbr += "<tr>"+rowItems+"</tr>"
				rowItems = ""
				totalColumns = 0
			end
			fileIndex += 1
		end
		
		if totalColumns != 0
			while (totalColumns >= 4) == false
				rowItems += "<td style=\"border: 1px solid black;\">&nbsp;<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"\" DISABLED/>
							Select
							</button><button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"\"  DISABLED/>
							View
							</button>&nbsp;---&nbsp;</td>"		
				totalColumns += 1
			end
		end
		
		if rowItems.length > 0
			tbr += "<tr>"+rowItems+"</tr>"
		end
		tbr += "		
						</table><br>
		"
		tbr += "
						<font size=\"3\">Temperature and Power Supply Power Sequence Configuration Files</font><br>"
		#
		# Create a list of Test Files, and display them in a table.
		# 						
		tbr += "<table style=\"border-collapse: collapse;	border: 1px solid black;\">"
		tbr += getRows(getListOfFiles("#{repoDir}","*.mincurr_config"))
		tbr += getRows(getListOfFiles("#{repoDir}","*.ps_config"))
		tbr += getRows(getListOfFiles("#{repoDir}","*.temp_config"))
		tbr += "		
						</table><br>
		"
		tbr += "
					<form 
						action=\"/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}\"
						
						method=\"post\" 
						enctype=\"multipart/form-data\">"
		tbr += "
						<font size=\"3\">Configuration File Uploader</font>
						<font size=\"1\">&nbsp;[&nbsp;Expected file fxtensions: *.step - for Step file;&nbsp;&nbsp;*.ps_config - for Power Supply sequence file;&nbsp;&nbsp;*.temp_config - for Temperature setting file;&nbsp;&nbsp;*.mincurr_config - for DUT Site Activation Min Current file.]</font>
						<br>
						<font size=\"2\">&nbsp;* Uploading files with similar names will over write old ones.</font>"
		if upLoadConfigErrorGeneral.nil? == false && upLoadConfigErrorGeneral.length > 0
				#
				# There's an error, show it to the user.
				#
				tbr += "<br><br>"
				tbr += "<font color=\"red\">Configuration File Error : "
				tbr += "#{upLoadConfigErrorGeneral}"
				tbr += "</font><br>"
		elsif upLoadConfigGoodUpload.nil? == false && upLoadConfigGoodUpload.length > 0
				tbr += "<br><br>"
				tbr += "<font color=\"green\"> "
				tbr += "#{upLoadConfigGoodUpload}"
				tbr += "</font><br>"
		elsif (upLoadConfigErrorRow.nil? == false && upLoadConfigErrorRow.length > 0) ||
			 (upLoadConfigErrorIndex.nil? == false && upLoadConfigErrorIndex.length > 0)
			if upLoadConfigErrorColType.nil? == false && upLoadConfigErrorColType.length > 0
				
				case upLoadConfigErrorColType
				when IndexCol
					errorType = "Index Column"
				when "nomSetCol"
					errorType = "Nominal Setting"
				when "tripMinCol"
					errorType = "Trip Minimum"
				when "tripMaxCol"
					errorType = "Trip Maximum"
				when "flagTolPCol"
					errorType = "flag Tolerance (+)"
				when "flagTolNCol"
					errorType = "flag Tolerance (-)"
				else
					errorType = "( '#{upLoadConfigErrorColType}' - not programmed to handle #{__LINE__}-#{__FILE__})"
				end			

				tbr += "<br><br>"
				tbr += "<font color=\"red\">Configuration File Error '#{upLoadConfigErrorInFile}' : "
				if errorType == "Index Column"
					tbr += "Value '#{upLoadConfigErrorValue}' on Row (#{upLoadConfigErrorRow}), '#{errorType}' \"MUST BE UNIQUE\".<br><br>"
				else 
					tbr += "Value '#{upLoadConfigErrorValue}' on Index (#{upLoadConfigErrorIndex}), '#{errorType}' column expects a numer.<br><br>"
				end
				tbr += "See sample template for configuration file."
				tbr += "</font><br>"
			else
				#
				# There's an error, show it to the user.
				#
				tbr += "<br><br>"
				tbr += "<font color=\"red\">Configuration File Error : "
				tbr += "Row (#{upLoadConfigErrorRow}), Col (#{upLoadConfigErrorCol}) does not recognize "
				tbr += "'#{upLoadConfigErrorName}' as an entry name.  "
				tbr += "See sample template for configuration file."
				tbr += "</font><br>"
			end
		elsif upLoadConfigErrorValue.length > 0
				#
				# There's an error, show it to the user.
				#
				tbr += "<br><br>"
				tbr += "<font color=\"red\">Configuration File Error : "
				tbr += "#{upLoadConfigErrorValue}"
				tbr += "See sample template for configuration file."
				tbr += "</font><br>"
		end
		tbr += "
						<br>
						<input type='file' name='myfile' />
						<br>
						<input type='submit' value='Upload' />
						<button 
							onclick=\"window.location='../'\"
							type=\"button\" 
	 						>
	 							Cancel
	 					</button>
						<br>
						<br>
						"
						

		if (upLoadConfigErrorRow.nil? == false && upLoadConfigErrorRow.length > 0) ||
			 (upLoadConfigErrorIndex.nil? == false && upLoadConfigErrorIndex.length > 0) ||
			 (upLoadConfigErrorGeneral.nil? == false && upLoadConfigErrorGeneral.length > 0)
			#
			# Set the proper config file type so proper template could be displayed on the file that is in error.
			#
			if @fileInError.nil? == false && @fileInError.length>0
				setConfigFileType(@fileInError)
			end
			 
			#
			# There's an error, show it to the user.
			#

			#
			# Get the max column in the template so we could draw our table correcty
			#
			if configFileType == SharedLib::PsConfig
				configTemplateRows = SharedLib.psConfigFileTemplate.split("\n")
			elsif configFileType == SharedLib::StepFileConfig
				configTemplateRows = SharedLib.stepConfigFileTemplate.split("\n")
			elsif configFileType == SharedLib::MinCurrConfig
				configTemplateRows = SharedLib.minCurrConfigFileTemplate.split("\n")
			else
				configTemplateRows = SharedLib.tempConfigFileTemplate.split("\n")
			end
			rowCt = 0
			maxColCt = getMaxColCt(configTemplateRows)
			
			tbr += "<center>Below is a sample configuration template.  Data must be in this given order, format, and comma for field delimiter.</center><br><br>"
			tbr += convertToTable(configTemplateRows,maxColCt)
		end
		tbr += "
					</form>
			</body>
		</html>
		"
		
			upLoadConfigErrorGeneral = ""  # Clear the message.
			upLoadConfigGoodUpload = "" # Clear the message.
		return tbr
		# end of 'def loadFile'
	end	
	
	def getKnownRowNamesFor(fileTypeParam)
=begin	
		if @lastKnownFileType != fileTypeParam
			@lastKnownFileType = fileTypeParam
			@hashUniqueIndex = Hash.new			
			@knownConfigRowNames = SharedLib.getKnownRowNamesFor(fileTypeParam)
		end
		
		return @knownConfigRowNames
=end
		@hashUniqueIndex = Hash.new			
		return SharedLib.getKnownRowNamesFor(fileTypeParam)
	end
	
	def hashUniqueIndex
		if @hashUniqueIndex.nil?
			@hashUniqueIndex = Hash.new
		end
		return @hashUniqueIndex
	end
	
	def checkConfigValue(valueParam, colnameParam, indexParam, rowParam,fromLine,fromFile)
		if (valueParam.length>0 && 
				colnameParam != UserInterface::IndexCol &&
				SharedLib.is_a_number?(valueParam) == false)
			@redirectWithError+="&ErrIndex=#{indexParam}&ErrColType=#{colnameParam}"
			@redirectWithError+="&ErrValue="+SharedLib.makeUriFriendly("#{valueParam}")
			return @redirectWithError
		elsif colnameParam == IndexCol
			#
			# Make sure that the index is unique, and not repeated.
			#
			if valueParam.length>0 && colnameParam==UserInterface::IndexCol
				#puts "valueParam=#{valueParam} hashUniqueIndex[valueParam]=#{hashUniqueIndex[valueParam]} hashUniqueIndex=#{hashUniqueIndex}"
				if hashUniqueIndex[valueParam].nil? == false
					redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
					redirectWithError += "&ErrRow=#{rowParam}&ErrColType=#{colnameParam}&ErrValue="+
						SharedLib.makeUriFriendly("#{valueParam}")
					return redirectWithError
				else
					hashUniqueIndex[valueParam] = "u" # u for unique
					return ""
				end
			else
				return ""
			end		
		else
			return ""
		end
	end
	
	def getSlotConfigStep(stepNameParam)
		#
		# configFileType can be ps_config, temp_config, or step
		#
		if getSlotProperties()["Steps"].nil? == true
			getSlotProperties()["Steps"] = Hash.new
		end
		
		stepHash = getSlotProperties()["Steps"]
		if stepHash[stepNameParam].nil? == true
			stepHash[stepNameParam] = Hash.new
		end
		
		return stepHash[stepNameParam]				
	end
	
	def setItemParameter(nameParam, param, valueParam)
		#
		# Get the value as data for processing the slot.
		#
		slotConfigStep = getSlotConfigStep(stepName)
		if slotConfigStep[configFileType].nil? == true
			slotConfigStep[configFileType] = Hash.new
		end		
		
		if slotConfigStep[configFileType][nameParam].nil?
			slotConfigStep[configFileType][nameParam] = Hash.new
		end
		# pause "stepName=#{stepName},configFileType=#{configFileType},nameParam=#{nameParam},param=#{param},valueParam=#{valueParam}"
		slotConfigStep[configFileType][nameParam][param] = valueParam.to_f
		# PP.pp(getSlotProperties()["Steps"])
		# pause("checking the new \"Steps\" value","#{__LINE__}-#{__FILE__}")

		# End of 'def setItemParameter(nameParam, param, valueParam)'
	end

	def setDataSetup(
					nameParam,unitParam,nomSetParam,tripMinParam,tripMaxParam,flagTolPParam,flagTolNParam,enableBitParam,
					idleStateParam,loadStateParam,startStateParam,runStateParam,stopStateParam,clearStateParam
				)
		setItemParameter(nameParam,Unit,unitParam)
		setItemParameter(nameParam,NomSet,nomSetParam)
		setItemParameter(nameParam,TripMin,tripMinParam)
		setItemParameter(nameParam,TripMax,tripMaxParam)
		setItemParameter(nameParam,FlagTolP,flagTolPParam)
		setItemParameter(nameParam,FlagTolN,flagTolNParam)
		setItemParameter(nameParam,EnableBit,enableBitParam)
		setItemParameter(nameParam,IdleState,idleStateParam)
		setItemParameter(nameParam,LoadState,loadStateParam)
		setItemParameter(nameParam,StartState,startStateParam)
		setItemParameter(nameParam,RunState,runStateParam)
		setItemParameter(nameParam,StopState,stopStateParam)
		setItemParameter(nameParam,ClearState,clearStateParam)
		# End of 
	end 
	
	def setBbbToStopMode(slotOwnerParam)
		hash = Hash.new
		hash[SharedLib::SlotOwner] = slotOwnerParam
		slotData = hash.to_json
		@response = 
      RestClient.post "#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::StopFromPc}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
		@sharedMem.SetDispButton(slotOwnerParam,"Seq Down")
	end
	
	def setToRunMode(slotOwnerParam)
		#
		# Send all info to BBB
		# 1) Make sure the BBB is up an running.
		# 	1.A) BBB's grape code is running so BBB can respond back to PC.
		#	2) Have the PC send the whole data to the BBB and have the BBB see if anything is different from
		#	it has in the system.  If there's a difference, update the data in BBB.
		#
		
		#
		# When it's in run mode, set the button to stop.
		#
		hash = Hash.new
		hash[SharedLib::SlotOwner] = slotOwnerParam
		slotData = hash.to_json
		@response = 
      RestClient.post "#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::RunFromPc}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
		@sharedMem.SetDispButton(slotOwnerParam,"Seq Up")
	end	

	def checkFaultyDutSiteActivationMinCurrentConfig(fileNameParam, fromParam)
		puts "Within checkFaultyDutSiteActivationMinCurrentConfig function."
		puts "Starting with function 'checkFaultyDutSiteActivationMinCurrentConfig' @redirectWithError='#{@redirectWithError}' #{__LINE__}-#{__FILE__}"
		# Returns true if no fault, false if there is error
		#
		clearError()
		
		# Read the content of the file...
		config = Array.new
		File.open("#{dirFileRepository}/#{fileNameParam}", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
		
		row = 3 # This row contains the pertinent data to have a good 'Dut Site Activation Min Current' config file.
		colContent = config[row].split(",")
		
		# Test the file content to make sure it has the following items in the file on a given row.
		tbr = true # tbr - to be returned
		if colContent[0] != "IDUT"
			#
			# The file content does not meet the content format of 'Dut Site Activation Min Current'
			#
			error = "In file '#{fileNameParam}' for \"DUT Site Activation Min Current File\".  Row 3, Col A expects the text 'IDUT'"
			@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
			tbr = false
		elsif colContent[1] != "DUT MINIMUM CURRENT [1:24]"
			#
			# The file content does not meet the content format of 'Dut Site Activation Min Current'
			#
			error = "In file '#{fileNameParam}' for \"DUT Site Activation Min Current File\".  Row 3, Col B expects the text 'DUT MINIMUM CURRENT [1:24]'"
			@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
			tbr = false
		elsif SharedLib.is_a_number?(colContent[3]) == false
			# Make sure that the column D is a number.
			error = "In file '#{fileNameParam}' for \"DUT Site Activation Min Current File\".  Row 3, Col D expects a number for minimum current.'"
			@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
			tbr = false
		else
			#
			# Set the 'DUT Site Activation Min' value
			#			
			slotConfigStep = getSlotConfigStep(PretestSiteIdentification)
			if slotConfigStep[SharedLib::DutSiteActivationMin].nil?
				slotConfigStep[SharedLib::DutSiteActivationMin] = colContent[3].chomp
			end
		end
		
		if tbr == false
				@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"+@redirectWithError
		end
		return true
	end
	
	def dutSiteActivationMinCurrentFileInFileSystem(colContent,configFileName)
		#
		# Make sure that the PS config file is present in the file system
		#
		if File.file?(dirFileRepository+"/"+colContent) == false
			#
			# The file does not exists.  Post an error.
			#
			@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
			@redirectWithError += "&ErrInFile="
			@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
			@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
			@redirectWithError += "&ErrStepPsNotFound=#{SharedLib.makeUriFriendly(colContent)}"
			return false
		else 
			#
			# Make sure the PS File config is good.
			#
			@configFileType = SharedLib::MinCurrConfig
			if checkFaultyDutSiteActivationMinCurrentConfig(colContent,"#{__LINE__}-#{__FILE__}") == false
				return false
			end
		end
	end
	
	def psConfigFileInFileSystem(colContent,configFileName)
		#
		# Make sure that the PS config file is present in the file system
		#
		if File.file?(dirFileRepository+"/"+colContent) == false
			#
			# The file does not exists.  Post an error.
			#
			@redirectWithError += "&ErrInFile="
			@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
			@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
			@redirectWithError += "&ErrStepPsNotFound=#{SharedLib.makeUriFriendly(colContent)}"
			return false
		else 
			#
			# Make sure the PS File config is good.
			#
			@configFileType = SharedLib::PsConfig
			if checkFaultyPsConfig(colContent,"#{__LINE__}-#{__FILE__}") == false
				return false
			end
		end
	end
	
	def parseTheConfigFile(config,configFileName)
		#
		# We got to parse the data.  Make sure that the data format is what Mike had provided by ensuring 
		# that the column item matches the known rows.
		#
		
		#
		# The following are the known rows
		# Ideally, get the the known row names from the template above vice having a separate column names here.
		#
		if @configFileType == SharedLib::StepFileConfig
			#
			# We're going to parse a step file.  Hard code settings:  "Item","Name","Description","Type","Value" are
			# starting on row 2, col A if viewed from Excel.
			#
			row = 0
			colContent = config[row].split(",")
			if (colContent[0].upcase.strip != "ITEM")
				@redirectWithError += "&ErrStepFormat=A"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
				return false
			elsif (colContent[1].upcase.strip != "NAME")
				@redirectWithError += "&ErrStepFormat=B"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
				return false
			elsif (colContent[2].upcase.strip != "DESCRIPTION")
				@redirectWithError += "&ErrStepFormat=C"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
				return false
			elsif (colContent[3].upcase.strip != "TYPE")
				@redirectWithError += "&ErrStepFormat=D"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
				return false
			elsif (colContent[4].upcase.strip != "VALUE")
				@redirectWithError += "&ErrStepFormat=E"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
				return false
			end
			
			#
			# Make sure that the pretest section has valid data.
			#
			
			# Make sure that the PS file for the pretest is valid.
			#   How are we going to check whether the file is present or not?
			ct = 2 # this is the row for the pretest power supply config file.
			@stepName = config[ct-1].split(",")[1].strip # Get the row data for file name.
			colContent = config[ct].split(",")[2].strip
			if colContent.nil? == true || colContent.length == 0
				@redirectWithError += "&ErrInFile="
				@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
				@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
				@redirectWithError += "&ErrPsFileNotGiven=Y"
				@redirectWithError = SharedLib.makeUriFriendly(@redirectWithError)				
				return false
			else
				if psConfigFileInFileSystem(colContent,configFileName) == false
					return false
				end
			end
			
			#
			# Make sure that the 'DUT Site Activation Min Current File' is present and valid.
			#
			ct = 4 # this is the row for the pretest 'DUT Site Activation Min Current File'
			@stepName = config[1].split(",")[1].strip # Get the row data for file name.
			colContent = config[ct].split(",")[2].strip
			if colContent.nil? == true || colContent.length == 0
				@redirectWithError += "&ErrInFile="
				@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
				@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
				@redirectWithError += "&ErrPsFileNotGiven=Y"
				@redirectWithError = SharedLib.makeUriFriendly(@redirectWithError)
				return false
			else
				if dutSiteActivationMinCurrentFileInFileSystem(colContent,configFileName) == false
					return false
				end
			end
			
			#
			# Make sure that the row "Step Name" column "Value" are unique and listed in order.
			#
			uniqueStepValue = Hash.new
			beginningLineOfSteps = 5
			ct = beginningLineOfSteps
			valueCounter = 1
			while ct < config.length do
				columns = config[ct].split(",")
				colName = config[ct].split(",")[1].strip # Get the row data for file name.
				if colName == "Step Name"
					# The section of the read file is still working on a step.
					@stepName = config[ct].split(",")[2].strip # Get the row data for file name.
					valueColumnOrStepNameRow = config[ct].split(",")[4].strip
					#
					# Must be a number test.
					#
					if SharedLib.is_a_number?(valueColumnOrStepNameRow) == false
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' "
							error += "on Step Name '#{columns[2]}' must be a number."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end
				
					#
					# Must be unique test.
					#
					if uniqueStepValue[valueColumnOrStepNameRow].nil? == false
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' "						
							error += "on Step Name '#{columns[2]}' must be unique."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end
				
					#
					# Must be in order test
					#
					if valueColumnOrStepNameRow.to_i != valueCounter
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' valueColumnOrStepNameRow.to_i=#{valueColumnOrStepNameRow.to_i} valueCounter=#{valueCounter} ct=#{ct} "
							error += "on Step Name '#{columns[2]}' must be listed in increasing order."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end				
					valueCounter += 1
				end
				ct += 11
			end
			
			#
			# Make sure that the step file has no two equal step names 
			#			
			uniqueStepNames = Hash.new
			ct = beginningLineOfSteps
			while ct < config.length do
				colContent = config[ct].split(",")[2].strip
				if uniqueStepNames[colContent].nil? == false
					#
					# The condition says that the step name is already used.  Can't process the file...
					#
					
					#
					# Verify we print the duplicate name error...
					#
					@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(configFileName)}"
					@redirectWithError += "&ErrStepNameAlreadyFound="
					@redirectWithError += "#{SharedLib.makeUriFriendly(colContent)}"					
					return false
				else
					if colContent.nil? == true || colContent.length == 0
						#
						#  Step name is blank.  This is not right.
						#
						@redirectWithError += "&ErrInFile="
						@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
						@redirectWithError += "&ErrStepNameNotGiven=Y"
						@redirectWithError += "&ErrRow=#{(ct+1)}"
						return false
					else
						#
						# Add the column name into the hash table so it can be accounted.
						#					
						uniqueStepNames[colContent] = "nn" # nn - not nil.
					end
				end				
				ct += 11
			end
			
			#
			# Make sure Power Supply setup file name are given.
			#
			ct = beginningLineOfSteps+1
			while ct < config.length do
				colName = config[ct].split(",")[1].strip
				if colName == 	"Power Supplies"
					@stepName = config[ct-1].split(",")[2].strip # Get the row data for file name.
					colContent = config[ct].split(",")[2].strip
					if colContent.nil? == true || colContent.length == 0
						@redirectWithError += "&ErrInFile="
						@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
						@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
						@redirectWithError += "&ErrPsFileNotGiven=Y"
						@redirectWithError = SharedLib.makeUriFriendly(@redirectWithError)
						return false
					else
						@configFileType = SharedLib::PsConfig
						if psConfigFileInFileSystem(colContent,configFileName) == false
							return false
						end
					end
				end
				ct += 11
			end

			
			#
			# Make sure the Temp Config file is given
			#
			ct = beginningLineOfSteps+2
			while ct < config.length do
				@stepName = config[ct-2].split(",")[2].strip # Get the row data for the step file name.
				colContent = config[ct].split(",")[2].strip
				if colContent.nil? == true || colContent.length == 0
					fromHere = "#{__LINE__}-#{__FILE__}"
					@redirectWithError += "&ErrInFile="
					@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
					@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
					@redirectWithError += "&ErrTempFileNotGiven=Y"
					return false
				else
					#
					# Make sure that the Temperature config file is present in the file system
					#
					if File.file?(dirFileRepository+"/"+colContent) == false
						#
						# The file does not exists.  Post an error.
						#
						@redirectWithError += "&ErrInFile="
						@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
						@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(@stepName)}"
						@redirectWithError += "&ErrStepTempNotFound=#{SharedLib.makeUriFriendly(colContent)}"
						return false
					else 
						#
						# Make sure the Temp File config is good.
						#
						@configFileType = SharedLib::TempConfig 
						if checkFaultyTempConfig(colContent,"#{__LINE__}-#{__FILE__}") == false
							return false
						end
					end
				end
				ct += 11
			end
						
			#
			# Make sure 'STEP TIME', 'Temp Wait Time', 'Alarm Wait Time' are numbers
			#
			offset = 3 # Due to Pretest (site identification.)
			if mustBeNumber(configFileName,2+offset,config,"Step Num") == false
					return false
			end
			
			if mustBeNumber(configFileName,6+offset,config,"Step Time") == false
					return false
			end
			
			if mustBeNumber(configFileName,7+offset,config,SharedMemory::TempWait) == false
					return false
			end

			if mustBeNumber(configFileName,8+offset,config,SharedMemory::AlarmWait) == false
					return false
			end
			
			#
			# Make sure that 'Auto Restart' and 'Stop on Tolerance' are boolean (1 or 0)
			#

			if mustBeBoolean(configFileName,9+offset,config,SharedMemory::AutoRestart) == false
					return false
			end
						
			if mustBeBoolean(configFileName,10+offset,config,SharedMemory::StopOnTolerance) == false
					return false
			end
			
			#
			# Get the sequence up and sequence down of power supplies
			#
			
		elsif @configFileType == SharedLib::PsConfig 
			@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}"
			@redirectWithError += "&BtnState=#{Load}"
			if checkFaultyPsConfig("#{configFileName}",
				"#{__LINE__}-#{__FILE__}") == false				
				return false
			end
			@redirectWithError += "&MsgFileUpload=#{SharedLib.makeUriFriendly(configFileName)}"
			return false
		elsif @configFileType == SharedLib::TempConfig 
			@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}"
			@redirectWithError += "&BtnState=#{Load}"
			if checkFaultyTempConfig("#{configFileName}",
				"#{__LINE__}-#{__FILE__}") == false				
				return false
			end
			@redirectWithError += "&MsgFileUpload=#{SharedLib.makeUriFriendly(configFileName)}"
			return false
		elsif @configFileType == SharedLib::MinCurrConfig					
			@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}"
			@redirectWithError += "&BtnState=#{Load}"
			if checkFaultyDutSiteActivationMinCurrentConfig("#{configFileName}",
				"#{__LINE__}-#{__FILE__}") == false				
				return false
			end
			@redirectWithError += "&MsgFileUpload=#{SharedLib.makeUriFriendly(configFileName)}"
			return false
		end		
		
		return true
		# End of def parseTheConfigFile(config)
	end

	def checkFaultyTempConfig(fileNameParam,fromParam)
		clearError()
		config = Array.new
		File.open("#{dirFileRepository}/#{fileNameParam}", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
		
		knownRowNames = getKnownRowNamesFor(configFileType)
		# puts "knownRowNames=#{knownRowNames} #{__LINE__}-#{__FILE__}"
		#
		# Make sure that each row have a column name that is found within the template which Mike provided.
		#
		ct = 0
		while ct < config.length do
			colContent = config[ct].split(",")[0].upcase
			if (colContent.length>0 && (knownRowNames[colContent].nil? || knownRowNames[colContent] != "nn"))
				#
				# How are we going to inform the user that the file is not a good one?
				#
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(fileNameParam)}&ErrRow=#{(ct+2)}&ErrCol=3&ErrName=#{colContent}"
				@redirectErrorFaultyPsConfig = redirectWithError
				return false
			end
			ct += 1
		end

		slotConfigStep = getSlotConfigStep(stepName)
		if slotConfigStep[configFileType].nil?
			slotConfigStep[configFileType] = Hash.new
		end
		
		ct = 2
		while ct < config.length do
			colName = config[ct].split(",")[0].upcase
			if colName == "TDUT"
				name = colName
				unit = nil
				nomSet = config[ct].split(",")[3].upcase
				tripMin = config[ct].split(",")[4].upcase
				tripMax = config[ct].split(",")[5].upcase
				flagTolP = config[ct].split(",")[6].upcase
				flagTolN = config[ct].split(",")[7].upcase
				enableBit = nil
				idleState = nil
				loadState = nil
				startState = nil
				runState = nil
				stopState = nil
				clearState = nil				
				setDataSetup(
					name,unit,nomSet,tripMin,tripMax,flagTolP,flagTolN,enableBit,idleState,
					loadState,startState,runState,stopState,clearState
				)
			else
				colContent = config[ct].split(",")[3].upcase
				# puts "colName='#{colName}' colContent='#{colContent}' #{__LINE__}-#{__FILE__}"
				slotConfigStep[configFileType][colName] = colContent
			end
			ct+=1
		end
	end

	def checkFaultyPsConfig(fileNameParam,fromParam)
=begin	
		puts "checkFaultyPsConfig got called. #{__LINE__}-#{__FILE__}"
		puts "fileNameParam=#{fileNameParam} #{__LINE__}-#{__FILE__}"
		puts "fromParam=#{fromParam} #{__LINE__}-#{__FILE__}"
		puts "configFileType=#{configFileType} #{__LINE__}-#{__FILE__}"
=end		
		#
		# Returns true if no fault, false if there is error
		#
		clearError()
		config = Array.new
		File.open("#{dirFileRepository}/#{fileNameParam}", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
		knownRowNames = getKnownRowNamesFor(configFileType)
		# puts "knownRowNames=#{knownRowNames} #{__LINE__}-#{__FILE__}"
		#
		# Make sure that each row have a column name that is found within the template which Mike provided.
		#
		ct = 0
		while ct < config.length do
			colContent = config[ct].split(",")[1].upcase
			if colContent.length>0 && (knownRowNames[colContent].nil? || knownRowNames[colContent] != "nn")
				#
				# How are we going to inform the user that the file is not a good one?
				#
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(fileNameParam)}&ErrRow=#{(ct+2)}&ErrCol=3&ErrName=#{colContent}"
				@redirectErrorFaultyPsConfig = redirectWithError
				return false
			end
			ct += 1
		end
		#
		# Rows to skip checking if values for Nom Set, Trip Min, Trip Max, Flag Tol+, Flog Tol- are numbers or not.
		skipNumCheckOnRows = Hash.new
		skipNumCheckOnRows["VPS5".upcase] = "nn" # nn - not nil.
		skipNumCheckOnRows["iPS5".upcase] = "nn"

		ct = 0
		indexCol = 0 #1
		nameCol = 1 #2
		unitCol = 3 #4
		nomSetCol = 4 # 5
		tripMinCol = 5# 6
		tripMaxCol = 6#7
		flagTolPCol = 7#8 # Flag Tolerance Positive
		flagTolNCol = 8#9 # Flag Tolerance Negative
		enableBitCol = 9#10 # Flag indicating that software can turn it on or off
		idleStateCol = 10#11 # Flag indicating that software can turn it on or off
		loadStateCol = 11#12 # Flag indicating that software can turn it on or off
		startStateCol = 12#13 # Flag indicating that software can turn it on or off
		runStateCol = 13#14 # Flag indicating that software can turn it on or off
		stopStateCol = 14#15 # Flag indicating that software can turn it on or off
		clearStateCol = 15#16 # Flag indicating that software can turn it on or off
		locationCol = 16#17 # Flag indicating that software can turn it on or off

		while ct < config.length do
			columns = config[ct].split(",")
			index = columns[indexCol].upcase 
			name = columns[nameCol].upcase
			unit = columns[unitCol].upcase

			nomSet = columns[nomSetCol].upcase
			tripMin = columns[tripMinCol].upcase
			tripMax = columns[tripMaxCol].upcase
			flagTolP = columns[flagTolPCol].upcase
			flagTolN = columns[flagTolNCol].upcase
			enableBit = columns[enableBitCol].upcase
			idleState = columns[idleStateCol].upcase
			loadState = columns[loadStateCol].upcase
			startState = columns[startStateCol].upcase
			runState = columns[runStateCol].upcase
			if configFileType != SharedLib::TempConfig
				stopState = columns[stopStateCol].upcase
				clearState = columns[clearStateCol].upcase
			end

			if skipNumCheckOnRows[name].nil?
				#
				# The row with the given name is not to be skipped.
				#
	
				#
				# Make sure that the index in the index colum is a number and they're unique.
				#
				@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}"
				@redirectWithError += "&BtnState=#{Load}"
				fromHere="#{__LINE__}-#{__FILE__}"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(fileNameParam)}"
				
				error = checkConfigValue(
					index,UserInterface::IndexCol,columns[indexCol],(ct+1),"#{__LINE__}","#{__FILE__}")				
				if error.length > 0
					@redirectErrorFaultyPsConfig = error
					return false
				end
		
				if unit == "M"
					#
					# Make sure that the following items -  nomSet,tripMin, tripMax, flagTolP, flagTolN are numbers
					#					
					error  = checkConfigValue(nomSet,"nomSetCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
					# End of 'if unit == "M"'
				elsif unit == "V" || unit == "A" || unit == "C"
					#
					# Make sure that the following items -  nomSet,tripMin, tripMax, flagTolP, flagTolN are numbers
					#					
					error = checkConfigValue(nomSet,"nomSetCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
		
					error = checkConfigValue(tripMin,"tripMinCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
		
					error = checkConfigValue(tripMax,"tripMaxCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
		
					error = checkConfigValue(flagTolP,"flagTolPCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
		
					error = checkConfigValue(flagTolN,"flagTolNCol",columns[1],(ct+1),"#{__LINE__}","#{__FILE__}")
					if error.length > 0
						@redirectErrorFaultyPsConfig = error
						return false
					end
					# End of 'elsif unit == "V" || unit == "A" || unit == "C"'
				end								
				
				if unit == "V" || unit == "A" || unit == "C" || unit == "M" || unit == "seconds" || unit == "Percent"|| unit == "Value"
					#
					# Get the data for processing
					#
					setDataSetup(
						name,unit,nomSet,tripMin,tripMax,flagTolP,flagTolN,enableBit,idleState,
						loadState,startState,runState,stopState,clearState
					)
				end
				# end of 'if skipNumCheckOnRows[name].nil?'
			end

			if colContent.length>0 && (knownRowNames[colContent].nil? || knownRowNames[colContent] != "nn")
				#
				# How are we going to inform the user that the file is not a good one?
				#
				@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
				@redirectWithError += "&ErrRow=#{ct+1}&ErrCol=3&ErrName=#{colContent}"
				return false
			end
			ct += 1
		end
		
		#
		# Get the sequence up and down order of power supplies.
		#
		
		#
		# Make sure that the sequence order are unique such that there are no same sequence number in the sequence
		# vice it's a zero.
		#
		seqUpCol = 5 #6
		seqUpDlyMsCol = 6 #7
		seqDownCol = 7 #8
		seqDownDlyMsCol = 8 #9
		sequenceUpHash = Hash.new
		sequenceDownHash = Hash.new
		@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
		ct = 0
		while ct < config.length do
			columns = config[ct].split(",")
			if columns[unitCol] == "SEQ"
				#
				# Make sure the sequence numbers are unique.
				#
				if columns[seqDownCol].to_i != 0
					if sequenceDownHash[columns[seqDownCol]].nil? 
						sequenceDownHash[columns[seqDownCol]] = "sntia" 
					else						
						error = "Error: In file '#{SharedLib.makeUriFriendly(fileNameParam)}', sequence number"
						error += " '#{columns[seqDownCol]}' on index '#{columns[indexCol]}' is already accounted for"
						error += " sequence down."
						puts "error @#{__LINE__}-#{__FILE__}"
						@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
						return false
					end
				end
				
				if columns[seqUpCol].to_i != 0				 
					if sequenceUpHash[columns[seqUpCol]].nil? 
						sequenceUpHash[columns[seqUpCol]] = "sntia" # sntia - sequence number taken into account
					else
						error = "Error: In file '#{SharedLib.makeUriFriendly(fileNameParam)}', sequence number"
						error += " '#{columns[seqUpCol]}' on index '#{columns[indexCol]}' is already accounted for" 
						error += " sequence up."
						puts "error @#{__LINE__}-#{__FILE__}"
						@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
						return false
					end
				end
								
				#
				# Make sure that if a given PS is 0 in sequence UP, it must also be 0 on sequence DOWN, and vice versa
				#
				if (columns[seqUpCol].to_i == 0 && columns[seqDownCol].to_i != 0) ||
					(columns[seqUpCol].to_i != 0 && columns[seqDownCol].to_i == 0) 
					error = "Error: In file '#{SharedLib.makeUriFriendly(fileNameParam)}' on"
					error += " index '#{columns[indexCol]}', if PS is turned off on "
					error += "power sequence (sequence order = 0), it must have a sequence = 0 for both SEQ UP and SEQ DN."
						puts "error @#{__LINE__}-#{__FILE__}"
					@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
					return false
				end
				
				#
				# Make sure that all sequence column have a value, and must not be left blank.
				#
				if emptyOrNotNumberTest(indexCol,fileNameParam,columns,
					columns[indexCol],seqUpCol,"SEQ UP") == false
					return false
				end
				
				if emptyOrNotNumberTest(indexCol,fileNameParam,columns,
					columns[indexCol],seqUpDlyMsCol,"SEQ UP DLYms") == false
					return false
				end
				
				if emptyOrNotNumberTest(indexCol,fileNameParam,columns,
					columns[indexCol],seqDownCol,"SEQ DN") == false
					return false
				end
				
				if emptyOrNotNumberTest(indexCol,fileNameParam,columns,
					columns[seqDownDlyMsCol],seqDownDlyMsCol,"SEQ DN DLYms") == false
					return false
				end
				
				slotConfigStep = getSlotConfigStep(stepName)
				if slotConfigStep[configFileType][columns[nameCol]].nil?
					slotConfigStep[configFileType][columns[nameCol]] = Hash.new
				end
				
				slotConfigStep[configFileType][columns[nameCol]]["EthernetOrSlotPcb"] = columns[4]
				slotConfigStep[configFileType][columns[nameCol]]["SeqUp"] = columns[5]
				slotConfigStep[configFileType][columns[nameCol]]["SUDlyms"] = columns[6]
				slotConfigStep[configFileType][columns[nameCol]]["SeqDown"] = columns[7]
				slotConfigStep[configFileType][columns[nameCol]]["SDDlyms"] = columns[8]
				# End of 'if columns[unitCol] == "SEQ"'
			end
			ct += 1
			# End of 'while ct < config.length do'
		end
		return true
		# End of 'checkFaultyPsConfig'	
	end
	
	def setupBbbSlotProcess(fileNameParam, slotOwnerParam)
		#
		# Find out what type of file we're dealing with:
		# *.step - for Step file
		# *.ps_config - for Power Supply sequence file
		# *.temp_config - for Temperature setting file.
		# *.mincurr_config - for DUT Site Activation Min Current file.
		#
		if setConfigFileType(fileNameParam) == false
			return false
		end
	

		config = Array.new
		File.open("#{dirFileRepository}/#{fileNameParam}", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
			
		if parseTheConfigFile(config,"#{fileNameParam}") == false
			return false
		end
		setConfigFileName("#{fileNameParam}")
		# PP.pp(slotProperties)
		if setBbbConfigUpload(slotOwnerParam) == false
			return false
		end
		
		return true
	end
	
	def emptyOrNotNumberTest(indexCol,fileNameParam,columns,indexParam, colNumParam,colNameParam)
		if columns[colNumParam].nil? || SharedLib.isInteger(columns[colNumParam]) == false	
			#
			# the indicated data is not a valid numbers.
			#
			error = "Error: In file '#{SharedLib.makeUriFriendly(fileNameParam)}', #{colNameParam} column"
			error += " on index '#{columns[indexCol]}' must be an integer."
						puts "error @#{__LINE__}-#{__FILE__}"
			@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
			return false
		end
	end

	def pause(paramA,paramLocation)
		puts "Paused at #{paramLocation} - #{paramA}"
		gets
	end
	
	def setConfigFileType(uploadedFileName)
		#
		# Returns true if the file is recognizes as one of the config file names.  Returns false if not.
		#
		stepFileExtension = ".step"
		psFileExtension = ".ps_config"
		temperatureFileExtension = ".temp_config"
		minCurrFileExtension = ".mincurr_config"
		
		stepFile = uploadedFileName[uploadedFileName.length-stepFileExtension.length..-1]
		psFile  = uploadedFileName[uploadedFileName.length-psFileExtension.length..-1]
		tempFile = uploadedFileName[uploadedFileName.length-temperatureFileExtension.length..-1]
		minCurrFile = uploadedFileName[uploadedFileName.length-minCurrFileExtension.length..-1]
		
		if stepFile == stepFileExtension
			@configFileType = SharedLib::StepFileConfig
		elsif psFile == psFileExtension
			@configFileType = SharedLib::PsConfig
		elsif tempFile == temperatureFileExtension
			@configFileType = SharedLib::TempConfig
		elsif minCurrFile == minCurrFileExtension
			@configFileType = SharedLib::MinCurrConfig
		else
			puts "error @#{__LINE__}-#{__FILE__}"
			@redirectWithError += "&ErrGeneral=FileNotKnown&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
			return false
		end
		
		return true
	end	
	
	def setFileInError(fileInError)
		@fileInError = fileInError
	end
	# End of class UserInterface
end
	
set :ui, UserInterface.new
set :port, 4569 # orig 4569

get '/about' do
	'A little about me.'
end

post '/AckError' do
end

get '/ViewFile' do
	config = Array.new
	File.open("#{settings.ui.dirFileRepository}/#{SharedLib.uriToStr(params[:File])}", "r") do |f|
		f.each_line do |line|
			config.push(line)
		end
	end
	tbr = ""; # tbr - to be returned
	tbr += "
	<FORM>"
	tbr += "File content of '#{SharedLib.uriToStr(params[:File])}'&nbsp;
		<INPUT Type=\"button\" VALUE=\"Back\" onClick=\"history.go(-1);return true;\"><br>
	"	
	# 
	# Convert the config file to table.
	#
	maxColCt = settings.ui.getMaxColCt(config)
	tbr += settings.ui.convertToTable(config,maxColCt)
	tbr += "
	</FORM>"
	return tbr
end

get '/TopBtnPressed' do
	settings.ui.setSlotOwner("#{SharedLib.uriToStr(params[:slot])}")
	if params[:File].nil? == false
		#
		# Setup the string for error
		#
		settings.ui.redirectWithError = "/TopBtnPressed?slot=#{settings.ui.getSlotOwner()}"
		settings.ui.redirectWithError += "&BtnState=#{settings.ui.Load}"	
		
		if settings.ui.setupBbbSlotProcess("#{params[:File]}","#{params[:slot]}") == false
			redirect settings.ui.redirectWithError
		end
		redirect "../"
	else
		if (SharedLib.uriToStr(params[:ErrGeneral]).nil? == false && SharedLib.uriToStr(params[:ErrGeneral]) != "")
			if SharedLib.uriToStr(params[:ErrGeneral]) == "FileNotKnown"	
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Unknown file extension.  Must be one of these: *.step, *.ps_config, *.mincurr_config, or *.temp_config"
			elsif SharedLib.uriToStr(params[:ErrGeneral]) == "bbbDown"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Board PcListener is down."
			elsif SharedLib.uriToStr(params[:ErrGeneral]) == "FileNotSelected"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', No file selected for upload."
			elsif SharedLib.uriToStr(params[:ErrGeneral]).nil? == false && 
						SharedLib.uriToStr(params[:ErrGeneral]).length >0
				settings.ui.upLoadConfigErrorGeneral = "#{SharedLib.uriToStr(params[:ErrGeneral])}"
				return settings.ui.loadFile
			end
		end		
		if SharedLib.uriToStr(params[:BtnState]) == settings.ui.Load	
			#
			# The Load button got pressed.
			#		
			settings.ui.setFileInError("#{SharedLib.uriToStr(params[:ErrInFile])}")
			if SharedLib.uriToStr(params[:ErrStepTempNotFound]).nil? == false && 
			SharedLib.uriToStr(params[:ErrStepTempNotFound]) != ""
				calledFrom = "#{__LINE__}-#{__FILE__}"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedLib.uriToStr(params[:ErrInStep])}'"
				settings.ui.upLoadConfigErrorGeneral += " Step Name, Temperature configuration file"
				settings.ui.upLoadConfigErrorGeneral += " '#{SharedLib.uriToStr(params[:ErrStepTempNotFound])}' is not found."
			elsif SharedLib.uriToStr(params[:ErrStepPsNotFound]).nil? == false && 
			SharedLib.uriToStr(params[:ErrStepPsNotFound]) != ""
				calledFrom = "#{__LINE__}-#{__FILE__}"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedLib.uriToStr(params[:ErrInStep])}'"
				settings.ui.upLoadConfigErrorGeneral += " Step Name, Power Supply configuration"
				settings.ui.upLoadConfigErrorGeneral += " '#{SharedLib.uriToStr(params[:ErrStepPsNotFound])}' is not found."
			elsif SharedLib.uriToStr(params[:ErrTempFileNotGiven]).nil? == false && 
			SharedLib.uriToStr(params[:ErrTempFileNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedLib.uriToStr(params[:ErrInStep])}' "
				settings.ui.upLoadConfigErrorGeneral += "Step Name, Temperature configuration file is not given."
			elsif SharedLib.uriToStr(params[:ErrPsFileNotGiven]).nil? == false && 
			SharedLib.uriToStr(params[:ErrPsFileNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedLib.uriToStr(params[:ErrInStep])}' "
				settings.ui.upLoadConfigErrorGeneral += "Step Name, Power Supply configuration file is not given."
			elsif SharedLib.uriToStr(params[:ErrStepNameNotGiven]).nil? == false && SharedLib.uriToStr(params[:ErrStepNameNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Row '#{SharedLib.uriToStr(params[:ErrRow])}' on step file requires a filename.."
			elsif SharedLib.uriToStr(params[:ErrStepNameAlreadyFound]).nil? == false && SharedLib.uriToStr(params[:ErrStepNameAlreadyFound]) != ""
				fileName = SharedLib.uriToStr(params[:ErrStepNameAlreadyFound])
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Duplicate filename '#{fileName}' in the step file list."
			elsif SharedLib.uriToStr(params[:ErrStepFormat]).nil? == false && SharedLib.uriToStr(params[:ErrStepFormat]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Step file format is incorrect.  Column labels must start on column A, row 1."
			elsif (SharedLib.uriToStr(params[:ErrGeneral]).nil? == false && SharedLib.uriToStr(params[:ErrGeneral]) != "")
				if SharedLib.uriToStr(params[:ErrGeneral]) == "FileNotKnown"	
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Unknown file extension.  Must be one of these: *.step, *.ps_config, *.mincurr_config, or *.temp_config"
				elsif SharedLib.uriToStr(params[:ErrGeneral]) == "bbbDown"
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Board PcListener is down."
				elsif SharedLib.uriToStr(params[:ErrGeneral]) == "FileNotSelected"
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', No file selected for upload."
				elsif SharedLib.uriToStr(params[:ErrGeneral]).nil? == false && 
							SharedLib.uriToStr(params[:ErrGeneral]).length >0
					settings.ui.upLoadConfigErrorGeneral = "#{SharedLib.uriToStr(params[:ErrGeneral])}"
				end
			elsif (SharedLib.uriToStr(params[:ErrRow]).nil? == false && SharedLib.uriToStr(params[:ErrRow]) != "") || 
				 (SharedLib.uriToStr(params[:ErrIndex]).nil? == false && SharedLib.uriToStr(params[:ErrIndex]) != "")
				settings.ui.upLoadConfigErrorInFile = SharedLib.uriToStr(params[:ErrInFile])
				settings.ui.upLoadConfigErrorIndex = SharedLib.uriToStr(params[:ErrIndex])
				settings.ui.upLoadConfigErrorRow = SharedLib.uriToStr(params[:ErrRow])
				settings.ui.upLoadConfigErrorCol = SharedLib.uriToStr(params[:ErrCol])
				settings.ui.upLoadConfigErrorName = SharedLib.uriToStr(params[:ErrName])
				settings.ui.upLoadConfigErrorColType = SharedLib.uriToStr(params[:ErrColType])
				settings.ui.upLoadConfigErrorValue = SharedLib.uriToStr(params[:ErrValue])
			elsif SharedLib.uriToStr(params[:MsgFileUpload]).nil? == false
				settings.ui.upLoadConfigGoodUpload = "File '#{SharedLib.uriToStr(params[:MsgFileUpload])}' has been uploaded."
				settings.ui.upLoadConfigErrorName = ""
			else
				settings.ui.clearError
			end
		
			return settings.ui.loadFile
		elsif SharedLib.uriToStr(params[:BtnState]) == settings.ui.Run
			#
			# The Run button got pressed.
			#
			settings.ui.setToRunMode(params[:slot])
			redirect "../"
		elsif SharedLib.uriToStr(params[:BtnState]) == settings.ui.Stop
			#
			# The Stop button got pressed.
			#
			settings.ui.setBbbToStopMode(params[:slot])
		
			#
			# Update the duration time
			# Formula : Time now - Time of run, then convert to hours, mins, sec.
			#
			redirect "../"
		elsif SharedLib.uriToStr(params[:BtnState]) == settings.ui.Clear
			#
			# The Clear button got pressed.
			#
			settings.ui.setToLoadMode(params[:slot])
			redirect "../"
		end
	end
end

get '/' do 
	return settings.ui.display
end

post '/' do	
	return settings.ui.display
end



post '/TopBtnPressed' do		
	if settings.ui.slotOwnerThe.nil? || settings.ui.slotOwnerThe == ""
		redirect "../"
	end
	settings.ui.clearError()

	tbr = "" # To be returned.
	
	#
	# Make sure that the "file repository" directory exists.
	#
	dirFileRepository = UserInterface::StepConfigFileFolder
	if Dir.exists?(dirFileRepository) == false
		#
		# Run a bash command to create a directory
		#
		`mkdir "#{dirFileRepository}"`
	end
	
	#
	# Setup the string for error
	#
	settings.ui.redirectWithError = "/TopBtnPressed?slot=#{settings.ui.getSlotOwner()}&BtnState=#{settings.ui.Load}"	
	
	if params['myfile'].nil?
		settings.ui.redirectWithError += "&ErrGeneral=FileNotSelected"
		redirect settings.ui.redirectWithError
	end

	goodUpload = true
	File.open("#{dirFileRepository}/#{params['myfile'][:filename]}" , "w") do |f|
		begin
			f.write(params['myfile'][:tempfile].read)
			rescue
				goodUpload = false
		end
	end
	
	if goodUpload
		#
		# Read the file into the server environment
		#
		if settings.ui.setupBbbSlotProcess("#{params['myfile'][:filename]}","#{params[:slot]}") == false
				redirect settings.ui.redirectWithError
		end
	end  
  
end

post '/AckError' do
	puts "post AckError"
end
 
get '/AckError' do
	newErrLogFileName = "../\"error logs\"/NewErrors_#{params[:slot]}.log"
	errLogFileName = "../\"error logs\"/ErrorLog_#{params[:slot]}.log"
	errorItem = `head -1 #{newErrLogFileName}`
	errorItem = errorItem.chomp
	puts "errorItem='#{errorItem}' errorItem.length=#{errorItem.length} #{__FILE__}-#{__LINE__}"
	if errorItem.length>0
		puts "at errLogFileName='#{errLogFileName}' #{__FILE__}-#{__LINE__}"
		newStr = SharedLib::MakeShellFriendly(errorItem)
		`echo \"#{newStr}\" >> #{errLogFileName}`	
	puts "at #{__FILE__}-#{__LINE__}"
=begin
	File.open(errLogFileName, "a") { 
		|file| file.write("#{errorItem}") 
	}
=end	
	puts "at #{__FILE__}-#{__LINE__}"

		trimmed = `sed -e '1,1d' < #{newErrLogFileName}`
	puts "at #{__FILE__}-#{__LINE__}"
		trimmed = trimmed.chomp
	puts "at #{__FILE__}-#{__LINE__}"
		if trimmed.length > 0
	puts "at #{__FILE__}-#{__LINE__}"
	puts "newErrLogFileName='#{newErrLogFileName}' #{__FILE__}-#{__LINE__}"
			trimmed = SharedLib::MakeShellFriendly(trimmed)
			`echo \"#{trimmed}\" > #{newErrLogFileName}`
	puts "at #{__FILE__}-#{__LINE__}"
		else
	puts "at #{__FILE__}-#{__LINE__}"
			`rm #{newErrLogFileName}`
	puts "at #{__FILE__}-#{__LINE__}"
		end
	puts "at #{__FILE__}-#{__LINE__}"
=begin	
	File.open(newErrLogFileName, "w") { 
		|file| file.write(trimmed) 
	}
=end	
	end
	settings.ui.clearErrorSlot("#{params[:slot]}")
	redirect "../"
end

# at 1013

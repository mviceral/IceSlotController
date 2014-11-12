# Code to look at:
# "BBB PcListener is down.  Need to handle this in production code level."
# @3073
require 'rubygems'
require 'sinatra'
development = true
require 'sinatra/reloader' if development?
#require 'sqlite3'
require 'json'
require 'rest_client'
require_relative '../lib/SharedLib'
require_relative '../lib/DRbSharedMemory/LibServer'
require_relative '../lib/SharedMemory'
require 'pp' # Pretty print to see the hash values.

require 'drb/drb'

class UserInterface
	SERVER_URI="druby://localhost:8787"
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
	attr_accessor :sharedMem
	
	def clearErrorSlot(slotOwnerParam)
		# puts "clearErrorSlot(slotOwnerParam) got called. slotOwnerParam='#{slotOwnerParam}' SharedLib::ErrorMsg='#{SharedLib::ErrorMsg}'"
		ds = @sharedMem.lockMemory("#{__LINE__}-#{__FILE__}")
		ds[SharedLib::PC][slotOwnerParam][SharedLib::ErrorMsg] = nil
		@sharedMem.writeAndFreeLocked(ds,"#{__LINE__}-#{__FILE__}")
	end

	def getBoardIp(slotParam, fromParam)
		if @slotToIp.nil?
			@slotToIp = Hash.new

			# Read the IP addresses from the file.
			lenOfStrToLookInto = "SLOT1 IP".length
  		File.open("../#{SharedLib::Pc_SlotCtrlIps}", "r") do |f|
  			f.each_line do |line|
#  				puts "line='#{line}' #{__LINE__}-#{__FILE__}"
					if line[0..(lenOfStrToLookInto-1)] == "SLOT1 IP"
						@slotToIp[SharedLib::SLOT1] = line[(lenOfStrToLookInto+1)..-1].strip
					elsif line[0..(lenOfStrToLookInto-1)] == "SLOT2 IP"
						@slotToIp[SharedLib::SLOT2] = line[(lenOfStrToLookInto+1)..-1].strip
					elsif line[0..(lenOfStrToLookInto-1)] == "SLOT3 IP"
						@slotToIp[SharedLib::SLOT3] = line[(lenOfStrToLookInto+1)..-1].strip
			    end
  			end
  		end
=begin  		
  		@slotToIp.each do |key, array|
				puts "#{key}-----"
				puts array
			end
			SharedLib.pause "Checking values of @slotToIp","#{__LINE__}-#{__FILE__}"
=end			
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
	
	def setConfigFileName(fileNameParam, lotIDParam)
		getSlotProperties()[FileName] = fileNameParam
		getSlotProperties()[SharedMemory::LotID] = lotIDParam
	end
	RowOfStepName = 8
	def mustBeBoolean(configFileName,ctParam,config,itemNameParam)
		#
		# returns true if the 
		#
		indexOfStepNameFromCt = ctParam - RowOfStepName
		ct = ctParam #9 "Auto Restart"
		while ct < config.length do
			stepName = config[ct-indexOfStepNameFromCt].split(",")[4].strip # Get the row data for the step file name.
			# puts "stepName = '#{stepName}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
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
			ct += @totalRowsToLookAt
			# End of 'while ct < config.length do' 
		end
		return true
	end
	
	def mustBeNumber(configFileName,ctParam,config,itemNameParam)
		#
		# returns true if the 
		#
		indexOfStepName = ctParam - RowOfStepName 
		# puts "ctParam='#{ctParam}', RowOfStepName='#{RowOfStepName}', indexOfStepName='#{indexOfStepName}'"
		ct = ctParam
		while ct < config.length && (ct-indexOfStepName) < config.length do
			# puts "ct='#{ct}', indexOfStepName='#{indexOfStepName}', ct-indexOfStepName='#{ct-indexOfStepName}', config.length='#{config.length}'"
			colName = config[ct-indexOfStepName].split(",")[1].strip # Get the row data for the step file name.
			stepName = config[ct-indexOfStepName].split(",")[4].strip # Get the row data for the step file name.
			# puts "stepName = '#{stepName}' indexOfStepName-ct='#{indexOfStepName-ct}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
			
			if colName == "Step Name"
				stepName = config[ct-indexOfStepName].split(",")[4].strip # Get the row data for the step file name.
			# puts "stepName = '#{stepName}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
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
			ct += @totalRowsToLookAt
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

	def sharedMem
		@sharedMem
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

	def getSystemID()
		if @systemID.nil?
			config = Array.new
			File.open("../#{SharedLib::Pc_SlotCtrlIps}", "r") do |f|
				f.each_line do |line|
					config.push(line)
				end			
			end
	
			# Parse each lines and mind the information we need for the report.
			ct = 0
			while ct < config.length 
				colContent = config[ct].split(":")
				if colContent[0] == "System ID"
					@systemID = colContent[1].chomp
					@systemID = @systemID.strip
				end
				ct += 1
			end
		end
		return @systemID
	end

	def setBbbConfigUpload(slotOwnerParam)
		slotProperties[slotOwnerParam][SharedLib::ConfigDateUpload] = Time.now.to_f
		slotProperties[slotOwnerParam][SharedLib::SlotOwner] = slotOwnerParam
		slotData = slotProperties[slotOwnerParam].to_json

		fileName = getSlotProperties()["FileName"]
		configDateUpload = getSlotProperties()[SharedLib::ConfigDateUpload]
		genFileName = SharedLib.getLogFileName(configDateUpload,SharedLib.getBibID(slotOwnerParam),slotProperties[slotOwnerParam][SharedMemory::LotID])
		settingsFileName =  genFileName+".log"
		recipeStepFile = "../steps config file repository/#{fileName}"
		recipeLastModified = File.mtime(recipeStepFile)
		
		writeToSettingsLog("Program: #{fileName}, Last modified: #{recipeLastModified}",settingsFileName)
		
		# Get the oven ID
		# Read the content of the file "#{SharedLib::Pc_SlotCtrlIps}" file to get the needed information...
		systemID = getSystemID()
		bibID = SharedLib.getBibID(slotOwnerParam)
		# writeToSettingsLog("System: #{systemID}, Slot: #{slotOwnerParam}",settingsFileName)
		hostName = `hostname -A`
		hostName = hostName.strip
		writeToSettingsLog("HostName: #{hostName}",settingsFileName)
		writeToSettingsLog("System: #{systemID}",settingsFileName)
		writeToSettingsLog("BIB#: #{bibID}",settingsFileName)
		writeToSettingsLog("Lot ID: #{getSlotProperties()[SharedMemory::LotID]}",settingsFileName)
		writeToSettingsLog("Slot Controller Software Ver: #{@sharedMem.GetDispCodeVersion(slotOwnerParam,SharedMemory::SlotCtrlVer)}",settingsFileName)
		writeToSettingsLog("PC Software Ver: #{@sharedMem.getCodeVersion(SharedMemory::PcVer)}",settingsFileName)
		writeToSettingsLog("",settingsFileName)

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
			puts "LoadConfig on IP='#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}'"
			
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
		toBeReturned += "<tr><td><font size=\"1\">N5V</font></td><td><font size=\"1\">-#{negVolt}V</font></td></tr>"
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

	def getStyle(vOrI,lorC,labelParam,errorColor)
		bgcolor = ""
		if errorColor.nil? == false
			sValue = labelParam[1..-1]
			if errorColor[vOrI+labelParam].nil? == false
				key = vOrI+labelParam
				case errorColor[key][lorC]
				when 1
				bgcolor = "#{SharedMemory::OrangeColor}"
				when 2
				bgcolor = "#{SharedMemory::RedColor}"
				end
			end
		end

		if bgcolor.nil? == false && bgcolor.length > 0
			return "style=\"background-color:#{bgcolor}\""
		else
			return ""
		end		
	end
	
	def PsCell(slotLabel2Param,labelParam,rawDataParam, iIndexParam)	
		errorColor = @sharedMem.GetDispErrorColor(slotLabel2Param)
		vStyleL = getStyle("V","Latch",labelParam,errorColor)
		vStyleC = getStyle("V","CurrentState",labelParam,errorColor)
		iStyleL = getStyle("I","Latch",labelParam,errorColor)
		iStyleC = getStyle("I","CurrentState",labelParam,errorColor)
		
		muxData = @sharedMem.GetDispMuxData(slotLabel2Param)
		adcData = @sharedMem.GetDispAdcInput(slotLabel2Param)
		rawDataParam = @sharedMem.getPsVolts(muxData,adcData,rawDataParam)

		eiPs = @sharedMem.GetDispEips(slotLabel2Param)
		current = @sharedMem.getPsCurrent(muxData,eiPs,iIndexParam,labelParam)

		cellColor = setBkColor(slotLabel2Param,"#6699aa")
		withinATag = false
		if cellColor == "#cccccc"
			# if slotLabel2Param == "SLOT1"		
				# puts "asfd #{__LINE__}-#{__FILE__}"
			# end
			toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
		else
			# if slotLabel2Param == "SLOT1"		
				# puts "asfd #{__LINE__}-#{__FILE__}"
			# end
			if @sharedMem.GetDispPsToolTip(slotLabel2Param).nil?
				# if slotLabel2Param == "SLOT1"		
					# puts "asfd #{__LINE__}-#{__FILE__}"
				# end
				toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
			else
				#if slotLabel2Param == "SLOT1"		
					# puts "asfd #{__LINE__}-#{__FILE__}"
				#end
				if @sharedMem.GetDispPsToolTip(slotLabel2Param)[labelParam].nil?
					if slotLabel2Param == "SLOT1"		
						# puts "asfd #{__LINE__}-#{__FILE__}"
					end
					toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
				else				
					if slotLabel2Param == "SLOT1"		
						# puts "asfd #{__LINE__}-#{__FILE__} '#{@sharedMem.GetDispPsToolTip(slotLabel2Param)[labelParam]}'"
					end
					toDisplay = "#{labelParam}-&#10;"
					toDisplay += @sharedMem.GetDispPsToolTip(slotLabel2Param)[labelParam]
					toBeReturned = "<a onClick=\"if (ctrlButtonPressed){alert('#{toDisplay}');}\"><table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
					toBeReturned.gsub! '&#10;', '\n'
					withinATag = true
				end
			end
		end
		toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
		toBeReturned += "<tr>"
		toBeReturned += "	<td #{vStyleL} >
												<font size=\"1\">Voltage</font>
											</td>
											<td #{vStyleC} >
												<font size=\"1\">#{rawDataParam}V</font>
											</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td #{iStyleL}><font size=\"1\">Current</font></td><td #{iStyleC}><font size=\"1\">#{current}A</font></td></tr>"
		
		if withinATag
			toBeReturned += "</table></a>"
		else
			toBeReturned += "</table>"
		end		
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end
	
	
	def getDutStyle(tOrI,lOrC,sValue,errorColor)
		if errorColor.nil?
				bgcolor1 = ""
				bgcolor2 = ""
		else
			if errorColor[tOrI].nil? == false && errorColor[tOrI][sValue].nil? == false
				case errorColor[tOrI][sValue][lOrC]
				when 0
					bgcolor1 = ""
				when 1
					bgcolor1 = "style=\"background-color:#{SharedMemory::OrangeColor}\""
				when 2
					bgcolor1 = "style=\"background-color:#{SharedMemory::RedColor}\""
				end
			end
		end
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
		splittedData = nil
		if tcuData == "---"
			cellColor = "#B6B6B4"
			enableToolTip = false
		else
			splittedData = tcuData.split(',')
			temperature = SharedLib.make5point2Format(splittedData[2])
			enableToolTip = true
		end
		# puts "rawDataParam=#{rawDataParam}, tcuData=#{tcuData} #{__LINE__}-#{__FILE__}"
		
		if enableToolTip
			# We need to get the Heating or Cooling state of the dut and the PWM value.
			if @sharedMem.GetDispDutToolTip(slotLabel2Param).nil? == false && @sharedMem.GetDispDutToolTip(slotLabel2Param).length > 0
				toDisplay = "DUT #{labelParam}-&#10;PWM:"
				if splittedData[3] == "0"
					toDisplay += "H@"+splittedData[4]
				else
					toDisplay += "C@"+splittedData[4]
				end
				toDisplay += "&#10;#{@sharedMem.GetDispDutToolTip(slotLabel2Param)}"
				# puts "slotLabel2Param='#{slotLabel2Param}' splittedData=#{splittedData}, tcuData='#{tcuData}' #{__LINE__}-#{__FILE__}"
			else
				toDisplay = ""
			end
			toBeReturned = "<a onClick=\"if (ctrlButtonPressed){alert('#{toDisplay}');}\"><table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
			toBeReturned.gsub! '&#10;', '\n'
			# puts "toBeReturned='#{toBeReturned}' #{__LINE__}-#{__FILE__}"
			# toBeReturned = "<table title=\"#{@sharedMem.GetDispDutToolTip(slotLabel2Param)}\" bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
		else
			toBeReturned = "<table bgcolor=\"#{cellColor}\" width=\"#{cellWidth}\">"
		end
		toBeReturned += "<tr><td><font size=\"1\">"+labelParam+"</font></td></tr>"
		toBeReturned += "<tr>"
		
		errorColor = @sharedMem.GetDispErrorColor(slotLabel2Param)
		sValue = labelParam[1..-1]		
		tStyleL = getDutStyle("TDUT","Latch",sValue,errorColor)
		tStyleC = getDutStyle("TDUT","CurrentState",sValue,errorColor)
		iStyleL = getDutStyle("IDUT","Latch",sValue,errorColor)
		iStyleC = getDutStyle("IDUT","CurrentState",sValue,errorColor)		
		toBeReturned += "	
			<td #{tStyleL} >
				<font size=\"1\">Temp</font>
			</td>
			<td #{tStyleC} >
				<font size=\"1\">#{temperature} C</font>
			</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td #{iStyleL}><font size=\"1\">Current</font></td><td #{iStyleC}><font size=\"1\">#{current} A</font></td></tr>"
		if enableToolTip
			toBeReturned += "</table></a>"
		else
			toBeReturned += "</table>"
		end
		
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
	def updatedSharedMemory
			@sharedMem = @sharedMemService.getSharedMem() # .processRecDataFromPC(.getDataFromBoardToPc())
			if @sharedMem.getCodeVersion(SharedMemory::PcVer).nil? || @sharedMem.getCodeVersion(SharedMemory::PcVer).length == 0
				@sharedMem.setCodeVersion(SharedMemory::PcVer,"1.0.0")
			end
	end
	def GetSlotDisplay(slotLabel2Param)
		lotID = @sharedMem.GetDispLotID(slotLabel2Param)
		if lotID.nil? == false && lotID.length > 0
			lotID = ", Lot ID: #{lotID}"
		else
			lotID = ""
		end
		return GetSlotDisplaySub("#{slotLabel2Param}/BIB#-#{SharedLib.getBibID(slotLabel2Param)}#{lotID}",slotLabel2Param)
	end
	
	def GetSlotDisplaySub(slotLabelParam,slotLabel2Param)		
		setSlotOwner(slotLabel2Param)
		getSlotDisplay_ToBeReturned = ""
		getSlotDisplay_ToBeReturned += 	
		"<table style=\"height:20%; border-collapse : collapse; border : 1px solid black;\"  bgcolor=\"#000000\">"
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
								"
=begin								
								"
								<td>&nbsp;</td>
								<td style=\"border:1px solid black; border-collapse:collapse; width: 95%;\">
									<font size=\"1\" color=\"red\"/>#{errMsg}
								</td>
								<td>
									<button onclick=\"window.location='/AckError?slot=#{slotLabel2Param}'\" style=\"height:20px;
									width:50px; font-size:10px\" />Ok</button>
								</td>
								"
=end								
		topTable += "
							</tr>
						</table>
					</td>
					<td valign=\"top\" rowspan=\"2\">
				 		<table>"
		stepNum = @sharedMem.GetDispStepNumber(slotLabel2Param)
		if @sharedMem.GetDispStopMessage(slotLabel2Param).nil? == false && @sharedMem.GetDispStopMessage(slotLabel2Param).length > 0
			topTable += "								
				 			<tr><td align=\"center\"><font size=\"1.75\"/>Step '#{stepNum}'</td></tr>
				 			<tr>
				 				<td style=\"background-color:#{SharedMemory::RedColor}\" align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">"
			disp = @sharedMem.GetDispStopMessage(slotLabel2Param)
			topTable += "		#{disp}				 							
				 					</font>
				 				</td>
				 			</tr>"
		elsif @sharedMem.GetDispBbbMode(slotLabel2Param) == SharedLib::InStopMode && @sharedMem.GetDispStepName(slotLabel2Param).length > 0
			topTable += "								
				 			<tr><td align=\"center\"><font size=\"1.75\"/>Step '#{stepNum}'</td></tr>
				 			<tr>
				 				<td align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">"
			disp = "Stopped"
			topTable += "		#{disp}				 							
				 					</font>
				 				</td>
				 			</tr>"
		elsif @sharedMem.GetDispWaitTempMsg(slotLabel2Param).nil? == false
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
				
				# Put the code here to chop up the log file if it's over 10meg in size.
				if @fileChoppedUp.nil?
					@fileChoppedUp = Hash.new
				end
				
				if @fileChoppedUp[slotLabel2Param] != @sharedMem.GetDispConfigurationFileName(slotLabel2Param)
					# So it would not run the code in this block again if it's true.
					@fileChoppedUp[slotLabel2Param] = @sharedMem.GetDispConfigurationFileName(slotLabel2Param)
					
					# See if the log file is over 10 meg.
					directory = SharedMemory::StepsLogRecordsPath
					generalFileName = SharedLib.getLogFileName(@sharedMem.GetDispConfigDateUpload(slotLabel2Param),SharedLib.getBibID(slotLabel2Param),@sharedMem.GetDispLotID(slotLabel2Param))
					dBaseFileName = generalFileName+".log"		
					# puts "dBaseFileName = '#{dBaseFileName}' #{__LINE__}-#{__FILE__}"
					fileitem = `ls -l #{directory}| grep #{dBaseFileName}`.strip
					# puts "fileitem = #{fileitem}"
					fileItemParts = fileitem.split(" ")					
=begin					
					puts "fileItemParts[0] = '#{fileItemParts[0]}' #{__LINE__}-#{__FILE__}"
					puts "fileItemParts[1] = '#{fileItemParts[1]}' #{__LINE__}-#{__FILE__}"
					puts "fileItemParts[2] = '#{fileItemParts[2]}' #{__LINE__}-#{__FILE__}"
					puts "fileItemParts[3] = '#{fileItemParts[3]}' #{__LINE__}-#{__FILE__}"
					puts "fileItemParts[4] = '#{fileItemParts[4]}' #{__LINE__}-#{__FILE__}"
					puts "fileItemParts[5] = '#{fileItemParts[5]}' #{__LINE__}-#{__FILE__}"					
					puts "fileItemParts[6] = '#{fileItemParts[6]}' #{__LINE__}-#{__FILE__}"
=end					
					if fileItemParts[4].to_i > 10000
						`cd #{directory}; split -b 10000000 #{dBaseFileName} #{generalFileName}_Part`
					end
				end
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
				topTable += "
				 			<tr><td align=\"center\"><font size=\"1.75\"/>STEP FILE NOT LOADED</td></tr>
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
			else
				stepNum = @sharedMem.GetDispStepNumber(slotLabel2Param)
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
				 			<tr><td align=\"center\">"
showButton = 1
buttonState = 0
if @sharedMem.GetDispErrorColor(slotLabel2Param).nil? == false
	@sharedMem.GetDispErrorColor(slotLabel2Param).each do |key, array|	
		if key == "TDUT" || key == "IDUT"
			array.each do |key2, array2|
				# puts "key2='#{key2}' #{__LINE__}-#{__FILE__}"
				array2.each do |key3, array3|
					if key3 == "Latch" && array3 != 0
						buttonState = showButton
					end
					
					if buttonState == showButton
						break
					end
				end
				
				if buttonState == showButton
					break
				end
			end
		else
			array.each do |key2, array2|
				if key2 == "Latch" && array2 != 0
					buttonState = showButton
				end
				
				if buttonState == showButton
					break
				end
			end
		end
		
		if buttonState == showButton
			break
		end
	end
	if buttonState == showButton
		topTable += "<a href=\"/TopBtnPressed?slot=#{slotLabel2Param}&BtnState=ClearError\" class=\"myButton\">Clear Error</a>"
	end
end
					topTable+=				 					
				 			"</td></tr>
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
		@sharedMem = @sharedMemService.getSharedMem() # .processRecDataFromPC(.getDataFromBoardToPc())
		displayForm =  ""	
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
			<body>
			"
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
										onclick=\"getLotId('#{getSlotOwner}','#{Load}','#{files[fileIndex]}');\" />
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
				<script type=\"text/javascript\">
					function getLotId(slotOwnerParam, btnStateParam, fileParam) {
						var defaultValue = \"--LOT ID--\";
						var lotID = prompt(\"Selected step config file: '\"+fileParam+\"'\\n\\nPlease provide the 'Lot ID' for this run:\", defaultValue);
						if (lotID != null && lotID!=defaultValue) {
							// Make sure that the inputed characters are all valid for filename.
							faultyInput = false;
							for (var a=0;a<lotID.length;a++) {
								ch = lotID.charAt(a);
								if (faultyInput == false && (ch==\"/\") || (ch.charCodeAt(0)==92) /* '\\'*/ || (ch==\"?\") || (ch==\"%\") || (ch==\"*\") || (ch==\":\") || (ch==\"|\") || (ch.charCodeAt(0)==34) /* '\"'*/ || (ch==\"<\") || ( ch==\">\") ||
								(ch ==\"#\") ||
								(ch == \"$\") ||
								(ch == \"+\") ||
								(ch == \"!\") ||
								(ch == \"`\") ||
								(ch == \"&\") ||
								(ch.charCodeAt(0)==39) /* single quote */ ||
								(ch == \"{\") ||
								(ch == \"=\") ||
								(ch == \"}\") ||
								(ch == \" \") ||
								(ch == \"@\") ) {
									faultyInput = true;
									break; // Break out of the loop.
								}
								// End of for loop.
							}
							
							if (faultyInput)
								// See reference.
								// http://www.mtu.edu/umc/services/web/cms/characters-avoid/
								alert (\"Entered Lot ID: '\"+lotID+\"'\\n\\nThe following chacters cannot be used for Lot ID: '/', '\\\\', '?', '%', '*', ':', '|', '\\\"', '<', '>', '#', '$', '+', '!', '`', '&', '‘', '{', '=', '}', ' ' (blank spaces), '@'..\\n\\nRe-select step config file and provide Lot ID to continue.\");
							else
								window.location=\"../TopBtnPressed?slot=\"+slotOwnerParam+\"&BtnState=\"+btnStateParam+\"&File=\"+encodeURIComponent(fileParam)+\"&LotID=\"+lotID+\"\";
						}
						else
						{
							alert (\"Lot ID not provided.  Re-select step config file and provide Lot ID to continue.\");
						}
					}
				</script>
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

		# puts "stepName='#{stepName}'"
		# PP.pp(slotConfigStep)
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
	def setBbbClearError(slotOwnerParam)
		hash = Hash.new
		hash[SharedLib::SlotOwner] = slotOwnerParam
		slotData = hash.to_json
		@response = 
      RestClient.post "#{getBoardIp(slotOwnerParam,"#{__LINE__}-#{__FILE__}")}:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::ClearErrFromPc}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
		@sharedMem.SetDispButton(slotOwnerParam,"Seq Down")
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
			@totalRowsToLookAt = 12
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
			@stepName = config[ct-1].split(",")[4].strip # Get the row data for file name.
			# puts "@stepName = '#{@stepName}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"

			colContent = config[ct].split(",")[4].strip
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
			@stepName = config[1].split(",")[4].strip # Get the row data for file name.
			# puts "@stepName = '#{@stepName}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
			colContent = config[ct].split(",")[4].strip
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
					@stepName = config[ct].split(",")[4].strip # Get the row data for file name.
			puts "@stepName = '#{@stepName}'"
			SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
					valueColumnOrStepNameRow = config[ct].split(",")[4].strip
					#
					# Must be a number test.
					#
					if SharedLib.is_a_number?(valueColumnOrStepNameRow) == false
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' "
							error += "on Step Name '#{columns[4]}' must be a number."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end
				
					#
					# Must be unique test.
					#
					if uniqueStepValue[valueColumnOrStepNameRow].nil? == false
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' "						
							error += "on Step Name '#{columns[4]}' must be unique."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end
				
					#
					# Must be in order test
					#
					if valueColumnOrStepNameRow.to_i != valueCounter
							error = "Error: In file '#{configFileName}', 'Value' "
							error += "'#{valueColumnOrStepNameRow}' valueColumnOrStepNameRow.to_i=#{valueColumnOrStepNameRow.to_i} valueCounter=#{valueCounter} ct=#{ct} "
							error += "on Step Name '#{columns[4]}' must be listed in increasing order."
							@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
							return false
					end				
					valueCounter += 1
				end
				ct += @totalRowsToLookAt
			end
			
			#
			# Make sure that the step file has no two equal step names 
			#			
			uniqueStepNames = Hash.new
			ct = beginningLineOfSteps
			while ct < config.length do
				colContent = config[ct].split(",")[4].strip
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
				ct += @totalRowsToLookAt
			end
			
			#
			# Make sure Power Supply setup file name are given.
			#
			ct = beginningLineOfSteps+1
			while ct < config.length do
				colName = config[ct].split(",")[1].strip
				if colName == 	"Power Supplies"
					@stepName = config[ct+2].split(",")[4].strip # Get the row data for file name.
			# puts "@stepName = '#{@stepName}' ct-3='#{ct-3}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
					colContent = config[ct].split(",")[4].strip
					colContent = colContent.chomp
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
				ct += @totalRowsToLookAt
			end

			
			#
			# Make sure the Temp Config file is given
			#
			ct = beginningLineOfSteps+2
			while ct < config.length do
				@stepName = config[ct+1].split(",")[4].strip # Get the row data for the step file name.
			# puts "@stepName = '#{@stepName}'"
			# SharedLib.pause "Checking","#{__LINE__}-#{__FILE__}"
				colContent = config[ct].split(",")[4].strip
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
				ct += @totalRowsToLookAt
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
			
			if mustBeNumber(configFileName,9+offset,config,SharedMemory::LoggingInt) == false
					return false
			end
			
			#
			# Make sure that 'Auto Restart' and 'Stop on Tolerance' are boolean (1 or 0)
			#

			if mustBeBoolean(configFileName,10+offset,config,SharedMemory::AutoRestart) == false
					return false
			end
						
			if mustBeBoolean(configFileName,11+offset,config,SharedMemory::StopOnTolerance) == false
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
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(fileNameParam)}&ErrRow=#{(ct+2)}&ErrCol=3&ErrName=#{SharedLib.makeUriFriendly(colContent)}"
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
		# PP.pp(slotConfigStep)
		# puts "stepName='#{stepName}'"
		# SharedLib.pause "Checking the configstep","#{__LINE__}-#{__FILE__}"
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
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(fileNameParam)}&ErrRow=#{(ct+2)}&ErrCol=3&ErrName=#{SharedLib.makeUriFriendly(colContent)}"
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
				@redirectWithError += "&ErrRow=#{ct+1}&ErrCol=3&ErrName=#{SharedLib.makeUriFriendly(colContent)}"
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
		seqUpCol = 5
		seqUpDlyMsCol = 6
		seqDownCol = 7
		seqDownDlyMsCol = 8
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
	
	def setupBbbSlotProcess(fileNameParam, slotOwnerParam, lotIDParam)
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
		
		setConfigFileName("#{fileNameParam}",lotIDParam)
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
	File.open("#{settings.ui.dirFileRepository}/#{SharedMemory.uriToStr(params[:File])}", "r") do |f|
		f.each_line do |line|
			config.push(line)
		end
	end
	tbr = ""; # tbr - to be returned
	tbr += "
	<FORM>"
	tbr += "File content of '#{SharedMemory.uriToStr(params[:File])}'&nbsp;
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
	settings.ui.setSlotOwner("#{SharedMemory.uriToStr(params[:slot])}")
	if params[:File].nil? == false
		#
		# Setup the string for error
		#
		settings.ui.redirectWithError = "/TopBtnPressed?slot=#{settings.ui.getSlotOwner()}"
		settings.ui.redirectWithError += "&BtnState=#{settings.ui.Load}"	
		# puts "LotID='#{params[:LotID]}'"
		# SharedLib.pause "Checking LotID","#{__LINE__}-#{__FILE__}"
		if settings.ui.setupBbbSlotProcess(params[:File],params[:slot],params[:LotID]) == false
			redirect settings.ui.redirectWithError
		end
		redirect "../"
	else
		if (SharedMemory.uriToStr(params[:ErrGeneral]).nil? == false && SharedMemory.uriToStr(params[:ErrGeneral]) != "")
			if SharedMemory.uriToStr(params[:ErrGeneral]) == "FileNotKnown"	
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Unknown file extension.  Must be one of these: *.step, *.ps_config, *.mincurr_config, or *.temp_config"
			elsif SharedMemory.uriToStr(params[:ErrGeneral]) == "bbbDown"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Board PcListener is down."
			elsif SharedMemory.uriToStr(params[:ErrGeneral]) == "FileNotSelected"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', No file selected for upload."
			elsif SharedMemory.uriToStr(params[:ErrGeneral]).nil? == false && 
						SharedMemory.uriToStr(params[:ErrGeneral]).length >0
				settings.ui.upLoadConfigErrorGeneral = "#{SharedMemory.uriToStr(params[:ErrGeneral])}"
				return settings.ui.loadFile
			end
		end		
		if SharedMemory.uriToStr(params[:BtnState]) == settings.ui.Load	
			#
			# The Load button got pressed.
			#		
			settings.ui.setFileInError("#{SharedMemory.uriToStr(params[:ErrInFile])}")
			if SharedMemory.uriToStr(params[:ErrStepTempNotFound]).nil? == false && 
			SharedMemory.uriToStr(params[:ErrStepTempNotFound]) != ""
				calledFrom = "#{__LINE__}-#{__FILE__}"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedMemory.uriToStr(params[:ErrInStep])}'"
				settings.ui.upLoadConfigErrorGeneral += " Step Name, Temperature configuration file"
				settings.ui.upLoadConfigErrorGeneral += " '#{SharedMemory.uriToStr(params[:ErrStepTempNotFound])}' is not found."
			elsif SharedMemory.uriToStr(params[:ErrStepPsNotFound]).nil? == false && 
			SharedMemory.uriToStr(params[:ErrStepPsNotFound]) != ""
				calledFrom = "#{__LINE__}-#{__FILE__}"
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedMemory.uriToStr(params[:ErrInStep])}'"
				settings.ui.upLoadConfigErrorGeneral += " Step Name, Power Supply configuration"
				settings.ui.upLoadConfigErrorGeneral += " '#{SharedMemory.uriToStr(params[:ErrStepPsNotFound])}' is not found."
			elsif SharedMemory.uriToStr(params[:ErrTempFileNotGiven]).nil? == false && 
			SharedMemory.uriToStr(params[:ErrTempFileNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedMemory.uriToStr(params[:ErrInStep])}' "
				settings.ui.upLoadConfigErrorGeneral += "Step Name, Temperature configuration file is not given."
			elsif SharedMemory.uriToStr(params[:ErrPsFileNotGiven]).nil? == false && 
			SharedMemory.uriToStr(params[:ErrPsFileNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', "
				settings.ui.upLoadConfigErrorGeneral += "Under '#{SharedMemory.uriToStr(params[:ErrInStep])}' "
				settings.ui.upLoadConfigErrorGeneral += "Step Name, Power Supply configuration file is not given."
			elsif SharedMemory.uriToStr(params[:ErrStepNameNotGiven]).nil? == false && SharedMemory.uriToStr(params[:ErrStepNameNotGiven]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Row '#{SharedMemory.uriToStr(params[:ErrRow])}' on step file requires a filename.."
			elsif SharedMemory.uriToStr(params[:ErrStepNameAlreadyFound]).nil? == false && SharedMemory.uriToStr(params[:ErrStepNameAlreadyFound]) != ""
				fileName = SharedMemory.uriToStr(params[:ErrStepNameAlreadyFound])
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Duplicate filename '#{fileName}' in the step file list."
			elsif SharedMemory.uriToStr(params[:ErrStepFormat]).nil? == false && SharedMemory.uriToStr(params[:ErrStepFormat]) != ""
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Step file format is incorrect.  Column labels must start on column A, row 1."
			elsif (SharedMemory.uriToStr(params[:ErrGeneral]).nil? == false && SharedMemory.uriToStr(params[:ErrGeneral]) != "")
				if SharedMemory.uriToStr(params[:ErrGeneral]) == "FileNotKnown"	
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Unknown file extension.  Must be one of these: *.step, *.ps_config, *.mincurr_config, or *.temp_config"
				elsif SharedMemory.uriToStr(params[:ErrGeneral]) == "bbbDown"
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', Board PcListener is down."
				elsif SharedMemory.uriToStr(params[:ErrGeneral]) == "FileNotSelected"
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedMemory.uriToStr(params[:ErrInFile])}', No file selected for upload."
				elsif SharedMemory.uriToStr(params[:ErrGeneral]).nil? == false && 
							SharedMemory.uriToStr(params[:ErrGeneral]).length >0
					settings.ui.upLoadConfigErrorGeneral = "#{SharedMemory.uriToStr(params[:ErrGeneral])}"
				end
			elsif (SharedMemory.uriToStr(params[:ErrRow]).nil? == false && SharedMemory.uriToStr(params[:ErrRow]) != "") || 
				 (SharedMemory.uriToStr(params[:ErrIndex]).nil? == false && SharedMemory.uriToStr(params[:ErrIndex]) != "")
				settings.ui.upLoadConfigErrorInFile = SharedMemory.uriToStr(params[:ErrInFile])
				settings.ui.upLoadConfigErrorIndex = SharedMemory.uriToStr(params[:ErrIndex])
				settings.ui.upLoadConfigErrorRow = SharedMemory.uriToStr(params[:ErrRow])
				settings.ui.upLoadConfigErrorCol = SharedMemory.uriToStr(params[:ErrCol])
				settings.ui.upLoadConfigErrorName = SharedMemory.uriToStr(params[:ErrName])
				settings.ui.upLoadConfigErrorColType = SharedMemory.uriToStr(params[:ErrColType])
				settings.ui.upLoadConfigErrorValue = SharedMemory.uriToStr(params[:ErrValue])
			elsif SharedMemory.uriToStr(params[:MsgFileUpload]).nil? == false
				settings.ui.upLoadConfigGoodUpload = "File '#{SharedMemory.uriToStr(params[:MsgFileUpload])}' has been uploaded."
				settings.ui.upLoadConfigErrorName = ""
			else
				settings.ui.clearError
			end
		
			return settings.ui.loadFile
		elsif SharedMemory.uriToStr(params[:BtnState]) == settings.ui.Run
			#
			# The Run button got pressed.
			#
			settings.ui.setToRunMode(params[:slot])
			redirect "../"
		elsif SharedMemory.uriToStr(params[:BtnState]) == settings.ui.Stop
			#
			# The Stop button got pressed.
			#
			settings.ui.setBbbToStopMode(params[:slot])
		
			#
			# Update the duration time
			# Formula : Time now - Time of run, then convert to hours, mins, sec.
			#
			redirect "../"
		elsif SharedMemory.uriToStr(params[:BtnState]) == settings.ui.Clear
			#
			# The Clear button got pressed.
			#
			settings.ui.setToLoadMode(params[:slot])
			redirect "../"
		elsif SharedMemory.uriToStr(params[:BtnState]) == "ClearError"
			#
			# The clear error button got pressed.
			#
			settings.ui.setBbbClearError(params[:slot])
			redirect "../"			
		end
	end
end

post '/dataDisplay' do
	settings.ui.updatedSharedMemory()
	tbr = "
		<table height=\"60%\" width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\">
			<tr><td align=\"left\">"
	tbr += settings.ui.GetSlotDisplay("SLOT1")
	tbr += "</td></tr>
			<tr><td align=\"left\">"
	tbr += settings.ui.GetSlotDisplay("SLOT2")
	tbr += "</td></tr>
			<tr><td align=\"left\">"
	tbr += settings.ui.GetSlotDisplay("SLOT3")
	tbr += "</td></tr>
		</table>		
	"				
	return tbr
end

get '/' do 
	# return settings.ui.display
	erb :home
end

post '/' do	
	# return settings.ui.display
	erb :home
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

__END__
@@home
<html lang="en">
	<head>
 		<title><%= settings.ui.getSystemID() %></title>
	<style>
	html, body {
    height: 100%;
	}
	
	.myButton {
		-moz-box-shadow:inset 1px 2px 3px 0px #91b8b3;
		-webkit-box-shadow:inset 1px 2px 3px 0px #91b8b3;
		box-shadow:inset 1px 2px 3px 0px #91b8b3;
		background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #768d87), color-stop(1, #6c7c7c));
		background:-moz-linear-gradient(top, #768d87 5%, #6c7c7c 100%);
		background:-webkit-linear-gradient(top, #768d87 5%, #6c7c7c 100%);
		background:-o-linear-gradient(top, #768d87 5%, #6c7c7c 100%);
		background:-ms-linear-gradient(top, #768d87 5%, #6c7c7c 100%);
		background:linear-gradient(to bottom, #768d87 5%, #6c7c7c 100%);
		filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#768d87', endColorstr='#6c7c7c',GradientType=0);
		background-color:#768d87;
		-moz-border-radius:2px;
		-webkit-border-radius:2px;
		border-radius:2px;
		border:1px solid #566963;
		display:inline-block;
		cursor:pointer;
		color:#ffffff;
		font-family:arial;
		font-size:10px;
		font-weight:bold;
		padding:0px 3px;
		text-decoration:none;
		text-shadow:0px -1px 0px #2b665e;
	}
	.myButton:hover {
		background:-webkit-gradient(linear, left top, left bottom, color-stop(0.05, #6c7c7c), color-stop(1, #768d87));
		background:-moz-linear-gradient(top, #6c7c7c 5%, #768d87 100%);
		background:-webkit-linear-gradient(top, #6c7c7c 5%, #768d87 100%);
		background:-o-linear-gradient(top, #6c7c7c 5%, #768d87 100%);
		background:-ms-linear-gradient(top, #6c7c7c 5%, #768d87 100%);
		background:linear-gradient(to bottom, #6c7c7c 5%, #768d87 100%);
		filter:progid:DXImageTransform.Microsoft.gradient(startColorstr='#6c7c7c', endColorstr='#768d87',GradientType=0);
		background-color:#6c7c7c;
	}
	.myButton:active {
		position:relative;
		top:1px;
	}

	#slotA
	{
	border:1px solid black;
	border-collapse:collapse;
	}
	</style>
	
	<script type="text/javascript">

	ct = 0;
	function updateBtnColor(SlotParam,ct) {
		var btn = document.getElementById("btn_"+SlotParam);
		if (ct == 0)
			btn.style="background: #ffaa77 no-repeat left;"
		if (ct == 1)
			btn.style="background: #ffaa00 no-repeat left;"			
		if (ct == 2)
			btn.style="background: #ff0077 no-repeat left;"			
		if (ct == 3)
			btn.style="background: #00aa77 no-repeat left;"
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
			xmlhttp=new ActiveXObject("Microsoft.XMLHTTP");
		}

		xmlhttp.onreadystatechange=function()
		{
			if (xmlhttp.readyState==4 && xmlhttp.status==200)
			{
				document.getElementById("myDiv").innerHTML=xmlhttp.responseText;
			}
		}	
		xmlhttp.open("POST","../dataDisplay",true);
		xmlhttp.send();
	}
	
	setInterval(function(){loadXMLDoc()},1000);  /*1000 msec = 1sec*/
	
	function isKeyPressed(event) {
		  if (event.ctrlKey) {
		  	ctrlButtonPressed = true;
		      /*alert("The CTRL key was pressed!");*/
		  } else {
		  	ctrlButtonPressed = false;
		  		/*alert("The CTRL key was NOT pressed!");*/		      
		  }
	}
	</script>
		<meta charset="utf-8">
	</head>
	<body onmousedown="isKeyPressed(event)">
		<%
			# Get the PC version, and Slot Ctrl version
			pcVer = ""
			slotCtrlVer = ""
			slotNum = 1
			while pcVer.nil? || pcVer.length == 0 || slotCtrlVer.nil? || slotCtrlVer.length == 0
				sleep(1)
				pcVer = settings.ui.sharedMem.getCodeVersion(SharedMemory::PcVer)
				# puts "SLOT#{slotNum} check.  Derived slotCtrlVer='#{slotCtrlVer}' pcVer='#{pcVer}' #{__LINE__}-#{__FILE__}"

				settings.ui.updatedSharedMemory()
				slotCtrlVer = settings.ui.sharedMem.GetDispCodeVersion("SLOT#{slotNum}",SharedMemory::SlotCtrlVer)
				# puts "SLOT#{slotNum} check.  Derived slotCtrlVer='#{slotCtrlVer}' pcVer='#{pcVer}' #{__LINE__}-#{__FILE__}"
				if slotCtrlVer.nil? || slotCtrlVer.length == 0
					slotNum += 1
					if slotNum >= 4
						slotNum = 1
					end
				end
			end

		%>
		<table>
			<tr>
				<td align="left"><img src="../ICE_logo_small.bmp" style="width:<%= 388/1.5 %>px;height:<%= 105/1.5%>px"></td>
				<td width="100%" align="center" colspan="3"><font size="5"><%= settings.ui.getSystemID() %></font></td>
				<td width="<%=388/1.5%>px">
					<table>
						<tr><td align="right" valign="bottom" nowrap><font size="1">PC ver:<%= pcVer %></font></td></tr>
						<tr><td align="right" valign="top" nowrap><font size="1">Slot Ctrl ver:<%= slotCtrlVer %></font></td></tr>
					</table>
				</td>
			</tf>
		</table>		
		<div style="height: 300px;" id="myDiv">
		</div>
	</body>
</html>

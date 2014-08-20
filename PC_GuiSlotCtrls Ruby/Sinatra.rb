# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
=begin
Trying to get the creation date of the uploaded file.
http://stackoverflow.com/questions/3018123/php-how-to-get-creation-date-from-uploaded-file

Solution, send the whole data and see if anything is different from what's send and what's in the BBB system.
If there's a difference, update the data in BBB.
-----------------------
To get images so it'll probably display on Sinatra
http://stackoverflow.com/questions/3493505/ruby-sinatra-serving-up-css-javascript-or-image-files
get '/notes/images/:file' do
  send_file('/root/dev/notes/images/'+SharedLib.uriToStr(params[:file]), :disposition => 'inline')
end
=end
# Code to look at:
# "The run duration is complete."
# "BBB PcListener is down.  Need to handle this in production code level."
# [***] - code not verified.
#
# make sure all the sequence code are working
# 
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'json'
require 'rest_client'
require_relative '../lib/SharedLib'
require 'pp' # Pretty print to see the hash values.

class UserInterface
	#
	# Template flags
	#
	StepFileTemplate = "StepFileTemplate"
	PSSeqFileTemplate = "PSSeqFileTemplate"
	TempSetTemplate = "TempSetTemplate"

	#
	# Settings file constants
	#
	IndexCol ="IndexCol"

	#
	# Constants for what is to be displayed.
	#
	BlankFileName = "-----------"
	FileName = "FileName"
	
	#
	# Button Labels.
	#
	Load = "Load"
	Run = "Run"
	Stop = "Stop"
	Clear = "Clear"
	
	#
	# Duration time labels
	#
	DurationHours = 	"DurationHours"
	DurationMins = "DurationMins"
	DurationHoursLeft = 	"DurationHoursLeft"
	DurationMinsLeft = "DurationMinsLeft"
	DurationSecsLeft = "DurationSecsLeft"
	
	#
	# Accessor for what's displayed on the top button of a slot
	#
	ButtonDisplay = "ButtonDisplay"
	
	#
	# Accessors for indicated times of a slot
	#
	TimeOfUpload = "TimeOfUpload"
	TimeOfRun = "TimeOfRun"
	TimeOfStop = "TimeOfStop"
	TimeOfClear = "TimeOfClear"
	
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
	
	def redirectErrorFaultyPsConfig
		@redirectErrorFaultyPsConfig
	end
	
	def dirFileRepository
		return "file repository"
	end

	def redirectWithError
		@redirectWithError
	end
	
	def mustBeBoolean(configFileName,ctParam,config,itemNameParam)
		#
		# returns true if the 
		#
		indexOfStepNameFromCt = ctParam - 2
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
				getSlotConfigStep(stepName)[itemNameParam] = stepTime
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
		ct = ctParam
		indexOfStepName = ctParam-2
		while ct < config.length do
			stepName = config[ct-indexOfStepName].split(",")[2].strip # Get the row data for the step file name.
			stepTime = config[ct].split(",")[4].strip
			if is_a_number?(stepTime) == false
				#
				# Given number is not good
				#
				@redirectWithError += "&ErrInFile="
				@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
				error = "Step File '#{configFileName}' - '#{itemNameParam}' '#{stepTime}' on line "
				error += "'#{ct+1}' must be a number."
				@redirectWithError += "&ErrGeneral=#{SharedLib.makeUriFriendly(error)}"
				return false
			else				
				getSlotConfigStep(stepName)[itemNameParam] = stepTime
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
									tbr += "<td style=\"border: 1px solid black;\"><font size=\"1\">"+columns[colCt]+"</font></td>"		
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
	end

	def getSlotOwner
		if @slotOwnerThe.nil? || @slotOwnerThe == ""
			getSlotsState
			redirect "../"
		end
		return @slotOwnerThe
	end
	
	def clearError
		getSlotProperties()[TimeOfUpload] = 0 # = 0 to indicate that this slot is not good for processing	
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

	def tempConfigFileTemplate
		#
		# Temperature config file template.
		#
		return ",,,Comment,,Nom,Trip,Trip,FLAG,FLAG,Enable,IDLE,LOAD,START,RUN,STOP,CLEAR
,index,Name,Type,Unit,SET,MIN,MAX,Tol+,Tol-,control,,,,,,
,1,TDUT,DUT TEMPERATURE [1:24],C,125,25,135,118.75,131.25,YES,OFF,OFF,ON,ON,OFF,OFF"
	end

	def stepConfigFileTemplate
		return ",,,,
		Item,Name,Description,Type,Value
		,Step Name,File Name A ,N,1
		1,Power Supplies,PS File Name A,File,
		2,Temperature,TMP File Name Z,File,
		3,Step Name,Step Name,T,STRING
		4,TIME,STEP TIME,M,2400
		5,TEMP WAIT,WAIT TIME ON TEMPERATURE,M,10
		6,Alarm Wait,WAIT TIME ON ALARM,M,1
		7,Auto Restart,Auto restart,B,1
		8,Stop on Tolerance,Stop on tolerance limit,B,0
		9,Text Vector,Test Vector Name & Path,T,STRING
		10,Next Step,Next Step Name 'B',T,STRING
		,Step Name,File Name B,N,2
		1,Power Supplies,PS File Name B,File,
		2,Temperature,TMP File Name Z,File,
		3,Step Name,Step Name,T,STRING
		4,TIME,STEP TIME,M,2400
		5,TEMP WAIT,WAIT TIME ON TEMPERATURE,M,10
		6,Alarm Wait,WAIT TIME ON ALARM,M,1
		7,Auto Restart,Auto restart,B,1
		8,Stop on Tolerance,Stop on tolerance limit,B,0
		9,Text Vector,Test Vector Name & Path,T,STRING
		10,Next Step,Next Step Name 'C',T,STRING
		,Step Name,File Name C,N,3
		1,Power Supplies,PS File Name C,File,
		2,Temperature,TMP File Name Z,File,
		3,Step Name,Step Name,T,STRING
		4,TIME,STEP TIME,M,2400
		5,TEMP WAIT,WAIT TIME ON TEMPERATURE,M,10
		6,Alarm Wait,WAIT TIME ON ALARM,M,1
		7,Auto Restart,Auto restart,B,1
		8,Stop on Tolerance,Stop on tolerance limit,B,0
		9,Text Vector,Test Vector Name & Path,T,STRING
		10,Next Step,Next Step Name 'END',T,STRING
		,if Condition,Count >= 10 END,F,FUNCTION
		,Count ++,incrament count,F,FUNCTION"
	end
	
	def psConfigFileTemplate
		return "
		,,,,,,,,,,,,,,,,,
		,,,,,,,,,,,,,,,,,
		,Config File,,,,,,,,,,Condition,,,,,,
		,,,Comment,,Nom,Trip,Trip,FLAG,FLAG,Enable,IDLE,LOAD,START,RUN,STOP,CLEAR,
		,index,Name,Type,Unit,SET,MIN,MAX,Tol+,Tol-,control,,,,,,,
		,15,VPS0,Slot PS Voltage 0,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,16,IPS0,Slot PS Current 0,A,125,0,140,14,131.25,,,,,,,,
		,17,VPS1,Slot PS Voltage 1,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,18,IPS1,Slot PS Current 1,A,125,0,140,14,131.25,,,,,,,,
		,19,VPS2,Slot PS Voltage 2  (shared PS2),V,1.5,1.35,1.65,1.425,1.575,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,20,IPS2,Slot PS Current 2 (shared PS2),A,70,0,70,7,73.5,,,,,,,,
		,21,VPS3,Slot PS Voltage 3,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,22,IPS3,Slot PS Current 3,A,125,0,140,14,131.25,,,,,,,,
		,23,VPS4,Slot PS Voltage 4  (shared PS2),V,1.5,1.35,1.65,1.425,1.575,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,24,IPS4,Slot PS Current 4  (shared PS2),A,70,0,70,7,73.5,,,,,,,,
		,25,VPS5,Slot PS Voltage 5,V,ph,ph,ph,ph,ph,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,26,IPS5,Slot PS Current 5,A,ph,ph,ph,ph,ph,,,,,,,,
		,27,VPS6,Slot PS Voltage 6,V,3.3,2.97,3.63,3.135,3.465,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
		,28,IPS6,Slot PS Current 6,A,3,0,5,0.5,3.15,,,,,,,,
		,29,VPS7,Slot PS Voltage 7,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
		,30,IPS7,Slot PS Current 7,A,125,0,140,14,131.25,,,,,,,,
		,31,VPS8,Slot PS Voltage 8,V,5,4.5,5.5,4.75,5.25,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
		,32,IPS8,Slot PS Current 8,A,1,0,3,0.3,1.05,,,,,,,,
		,33,VPS9,Slot PS Voltage 9,V,2.1,1.89,2.31,1.995,2.205,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
		,34,IPS9,Slot PS Current 9,A,1,0,3,0.3,1.05,,,,,,,,
		,35,VPS10,Slot PS Voltage 10,V,2.5,2.25,2.75,2.375,2.625,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
		,36,IPS10,Slot PS Current 10,A,3,0,5,0.5,3.15,,,,,,,,
		,37,IDUT,Dut PS current 24 [1:24],A,23,0,27,2.7,24.15,,,,,,,,
		,,,,,,UP,DLYms,DN,DLYms,,,,,,,,
		,39,SPS0,Enable-Disable ,SEQ,Ethernent,3,100,9,200,,,,,,,,
		,40,SPS1,Enable-Disable ,SEQ,Ethernent,1,500,8,200,,,,,,,,
		,41,SPS2,Enable-Disable ,SEQ,Ethernent,2,1000,7,200,,,,,,,,
		,42,SPS3,Enable-Disable ,SEQ,Ethernent,4,200,6,200,,,,,,,,
		,43,SPS4,Enable-Disable ,SEQ,Ethernent,0,0,0,0,,,,,,,,
		,44,SPS5,Enable-Disable ,SEQ,Ethernent,0,0,0,0,,,,,,,,
		,45,SPS6,Enable-Disable ,SEQ,Slot PCB,5,200,5,200,,,,,,,,
		,46,SPS7,Enable-Disable ,SEQ,,6,200,4,200,,,,,,,,
		,47,SPS8,Enable-Disable ,SEQ,Slot PCB,7,200,3,200,,,,,,,,
		,48,SPS9,Enable-Disable ,SEQ,Slot PCB,8,200,2,200,,,,,,,,
		,49,SPS10,Enable-Disable ,SEQ,Slot PCB,9,200,1,200,,,,,,,,"
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
	
	def updateDurationTimeLeft()
		dl = GetSlotDurationHoursLeft().to_i*60*60 # dl - duration left
		dl += GetSlotDurationMinsLeft().to_i*60
		dl += GetSlotDurationSecsLeft().to_i
		dl -= (getSlotProperties()[TimeOfStop].to_i-getSlotProperties()[TimeOfRun].to_i) # dl is duration left
		
		hours = (dl/3600).to_i
		dl -= hours*3600
		mins = (dl/60).to_i
		dl -= (mins*60).to_i
		getSlotProperties()[DurationHoursLeft] = hours
		getSlotProperties()[DurationMinsLeft] = mins
		getSlotProperties()[DurationSecsLeft] = dl.to_i
	end

	def GetDurationLeft()
		# If the button state is Stop, subtract the total time between now and TimeOfRun, then 
		if getSlotProperties()[ButtonDisplay] == Stop
			#
			# What does it return?
			#
			dl = GetSlotDurationHoursLeft().to_i*60*60 # dl - duration left
			dl += GetSlotDurationMinsLeft().to_i*60
			dl += GetSlotDurationSecsLeft().to_i
			if getSlotProperties()[TimeOfRun].nil?
				"00:00:00"
			else
				dl -= (Time.new.to_i - getSlotProperties()[TimeOfRun].to_i)
				hours = (dl/3600).to_i
				dl -= hours*3600
				mins = (dl/60).to_i
				dl -= (mins*60).to_i
		
				if dl<0
					#
					# The run duration is complete.
					#
				end
		
				return "#{hours}:#{mins}:#{dl.to_i}"
			end
		elsif getSlotProperties()[ButtonDisplay] == Run
				return "#{GetSlotDurationHoursLeft()}:#{GetSlotDurationMinsLeft()}:#{GetSlotDurationSecsLeft()}"
		end
	end 

	def make2Digits(paramDigit)
		if paramDigit.length < 2
			paramDigit = "0"+paramDigit
		end
		return paramDigit
	end
	
	def getSlotsState
		begin
			fileRead = ""
			File.open('SlotState_DoNotDeleteNorModify.json', "r") do |f|
				f.each_line do |line|
					fileRead += line
				end
			end
			@slotProperties = JSON.parse(fileRead)
			rescue 
				# File does not exists, so just continue with a blank slate.
		end
	end
	
	def getStepCompletion()	
		if slotProperties.to_json == "{}"
			getSlotsState()
		end		
		
		if getSlotProperties()[ButtonDisplay] == Load 
			return BlankFileName
		else
			if getSlotProperties()[ButtonDisplay] == Run
				d = Time.now
				d += GetSlotDurationHoursLeft().to_i*60*60
				d += GetSlotDurationMinsLeft().to_i*60
				d += GetSlotDurationSecsLeft().to_i
			else
				d = getSlotProperties()[TimeOfRun].to_i
				d += GetSlotDurationHoursLeft().to_i*60*60 # dl - duration left
				d += GetSlotDurationMinsLeft().to_i*60
				d += GetSlotDurationSecsLeft().to_i			
				d = Time.at(d)
			end
		
			month = d.month.to_s # make2Digits(d.month.to_s)
			day = d.day.to_s # make2Digits(d.day.to_s)
			year = d.year.to_s
			hour = make2Digits(d.hour.to_s)
			min = make2Digits(d.min.to_s)
			sec = make2Digits(d.sec.to_s)
			return month+"/"+day+"/"+year+" "+hour+":"+min+":"+sec
		end
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
	def setConfigFileName(fileNameParam)
		getSlotProperties()[FileName] = fileNameParam
	end
	
	def setDurationHours(durationHoursParam)
		getSlotProperties()[DurationHours] = durationHoursParam
		getSlotProperties()[DurationHoursLeft] = durationHoursParam
	end
	
	def setTimeOfRun()
		getSlotProperties()[TimeOfRun] = Time.now.to_i
	end
	
	def setTimeOfStop()
		getSlotProperties()[TimeOfStop] = Time.now.to_i
	end
	
	def setTimeOfClear()
		getSlotProperties()[TimeOfClear] = Time.now.to_i
	end
		
	def saveSlotState()
		#
		# Save the slot states of the environment.
		# How's that going to work?
		# - Open up a file, and save the Slot Properties
		#
		if slotProperties.to_json == "{}"
			getSlotsState()
		end		
		File.open("SlotState_DoNotDeleteNorModify.json", "w") { |file| file.write(slotProperties.to_json) }
	end
	
	def setTimeOfUpload()
		getSlotProperties()[TimeOfUpload] = Time.now
	end
	
	def setDurationMinutes(totalMinutesParam)
		getSlotProperties()[DurationMins] = totalMinutesParam
		getSlotProperties()[DurationMinsLeft] = totalMinutesParam		
	end
	
	def getButtonImage()
		if getSlotProperties()[BtnDisplayImg].nil?
			getSlotProperties()[BtnDisplayImg] = LoadImg
		end
		return getSlotProperties()[BtnDisplayImg]
	end
	
	def getButtonDisplay(slotLabelParam)
		setSlotOwner(slotLabelParam)
		if getSlotProperties()[ButtonDisplay].nil?
			getSlotProperties()[ButtonDisplay] = Load
		end
		return getSlotProperties()[ButtonDisplay]
	end
	
	def setToLoadMode()
		setConfigFileName(BlankFileName)
		setDurationHours("00")
		setDurationMinutes("00")
		getSlotProperties()[ButtonDisplay] = Load
	end

	def setBbbConfigUpload()
		slotData = getSlotProperties().to_json
		begin
			@response = 
		    RestClient.post "http://192.168.7.2:8000/v1/pclistener/", { PcToBbbCmd:"#{SharedLib::LoadConfigFromPC}",PcToBbbData:"#{slotData}" }.to_json, :content_type => :json, :accept => :json
			rescue
			redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
			redirectWithError += "&ErrGeneral=bbbDown"
			return redirectWithError
		end
	end

	def setToAllowedToRunMode()
		getSlotProperties()[ButtonDisplay] = Run
	end
	
	def cellWidth
		return 95
	end

	def initialize		
		# end of 'def initialize'
	end

	def SlotCell(temp1Param, temp2Param)
		toBeReturned = "<table bgcolor=\"#ffaa77\" width=\"#{cellWidth}\">"
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

	def PNPCell(posVolt, negVolt, largeVolt)
		toBeReturned = "<table bgcolor=\"#6699aa\" width=\"#{cellWidth}\">"
		toBeReturned += "<tr><td><font size=\"1\">P5V</font></td><td><font size=\"1\">#{posVolt}V</font></td></tr>"
		toBeReturned += "<tr><td><font size=\"1\">N5V</font></td><td><font size=\"1\">#{negVolt}V</font></td></tr>"
		toBeReturned += "<tr><td><font size=\"1\">P12V</font></td><td><font size=\"1\">#{largeVolt}V</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def PsCell(labelParam,rawDataParam)
		rawDataParam = rawDataParam[0].partition("@")
		isRunning = rawDataParam[2].partition(",")
		ambientTemp = isRunning[2].partition(",")
		dutTemp = ambientTemp[2].partition(",")
		toBeReturned = "<table bgcolor=\"#6699aa\" width=\"#{cellWidth}\">"
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
												<font size=\"1\">#{dutTemp[0]}V</font>
											</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">###A</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def DutCell(labelParam,rawDataParam)
		rawDataParam = rawDataParam[0].partition("@")
		isRunning = rawDataParam[2].partition(",")
		ambientTemp = isRunning[2].partition(",")
		dutTemp = ambientTemp[2].partition(",")
		toBeReturned = "<table bgcolor=\"#99bb11\" width=\"#{cellWidth}\">"
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
				<font size=\"1\">#{dutTemp[0]}C</font>
			</td>"
		toBeReturned += "</tr>"
		toBeReturned += "<tr><td><font size=\"1\">Current</font></td><td><font size=\"1\">###A</font></td></tr>"
		toBeReturned += "</table>"
		return toBeReturned
		# End of 'DutCell("S20",dut20[2])'
	end

	def GetSlotDurationSecsLeft()
		if getSlotProperties()[DurationSecsLeft].nil?
			getSlotProperties()[DurationSecsLeft] = "00"
		end
		return getSlotProperties()[DurationSecsLeft]
	end

	def GetSlotDurationMinsLeft()
		if getSlotProperties()[DurationMinsLeft].nil?
			getSlotProperties()[DurationMinsLeft] = "00"
		end
		return getSlotProperties()[DurationMinsLeft]
	end
	
	def GetSlotDurationHoursLeft()
		if getSlotProperties()[DurationHoursLeft].nil?
			getSlotProperties()[DurationHoursLeft] = "00"
		end
		return getSlotProperties()[DurationHoursLeft]
	end
	
	def GetSlotDurationHours()
		if getSlotProperties()[DurationHours].nil?
			return "00"
		else
			return getSlotProperties()[DurationHours]
		end
	end 
	
	def GetSlotDurationMins()
		if getSlotProperties()[DurationMins].nil?
			return "00"
		else
			return getSlotProperties()[DurationMins]
		end
	end 
	
	def getRows(dirParam)
		repoDir = "file\ repository"
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
		
	def GetSlotFileName ()
		if getSlotProperties()[FileName].nil?
			return BlankFileName
		else
			return getSlotProperties()[FileName]
		end
		# End of 'def GetSlotFileName (slotLabelParam)'
	end
	
	def removeWhiteSpace(slotLabelParam)
		return slotLabelParam.delete(' ')
	end
	
	def GetSlotDisplay (slotLabelParam,slotLabel2Param)
		setSlotOwner(slotLabel2Param)
		getSlotDisplay_ToBeReturned = ""
		begin
			db = SQLite3::Database.open "latest.db"
			db.results_as_hash = true
			ary = db.execute "SELECT * FROM latest where idData = 1"    
			ary.each do |row|				
				dut0 = row['slotData'].partition("|")
				dut1 = dut0[2].partition("|")
				dut2 = dut1[2].partition("|")
				dut3 = dut2[2].partition("|")
				dut4 = dut3[2].partition("|")
				dut5 = dut4[2].partition("|")
				dut6 = dut5[2].partition("|")
				dut7 = dut6[2].partition("|")
				dut8 = dut7[2].partition("|")
				dut9 = dut8[2].partition("|")
				dut10 = dut9[2].partition("|")
				dut11 = dut10[2].partition("|")
				dut12 = dut11[2].partition("|")
				dut13 = dut12[2].partition("|")
				dut14 = dut13[2].partition("|")
				dut15 = dut14[2].partition("|")
				dut16 = dut15[2].partition("|")
				dut17 = dut16[2].partition("|")
				dut18 = dut17[2].partition("|")
				dut19 = dut18[2].partition("|")
				dut20 = dut19[2].partition("|")
				dut21 = dut20[2].partition("|")
				dut22 = dut21[2].partition("|")
				dut23 = dut22[2].partition("|")

				getSlotDisplay_ToBeReturned += 	
				"<table style=\"border-collapse : collapse; border : 1px solid black;\"  bgcolor=\"#000000\">"
				getSlotDisplay_ToBeReturned += 	"<tr>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S20",dut20)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S16",dut16)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S12",dut12)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S8",dut8)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S4",dut4)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S0",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS0",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS4",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS8",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("5V",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	"</tr>"
				getSlotDisplay_ToBeReturned += 	"<tr>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S21",dut21)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S17",dut17)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S13",dut13)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S9",dut9)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S5",dut5)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S1",dut1)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS1",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS5",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS9",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("12V",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	"</tr>"
				getSlotDisplay_ToBeReturned += 	"<tr>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S22",dut22)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S18",dut18)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S14",dut14)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S10",dut10)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S6",dut6)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S2",dut2)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS2",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS6",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS10",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("24V",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	"</tr>"
				getSlotDisplay_ToBeReturned += 	"<tr>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S23",dut23)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S19",dut19)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S15",dut15)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S11",dut11)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S7",dut7)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+DutCell("S3",dut4)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS3",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+PsCell("PS7",dut0)+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : 
					collapse; border : 1px solid black;\">"+PNPCell("5.01","-5.10","12.24")+"</td>"
				getSlotDisplay_ToBeReturned += 	
				"<td style=\"border-collapse : collapse; border : 1px solid black;\">"+SlotCell("55.5","45.5")+"</td>"
				getSlotDisplay_ToBeReturned += 	"</tr>"
				getSlotDisplay_ToBeReturned += 	"</table>"
			end
		
			rescue SQLite3::Exception => e 
				  puts "Exception occured"
				  puts e

			ensure
				  db.close if db		
		end
		
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
								<td style=\"border:1px solid black; border-collapse:collapse; width: 100%;\">
									<font size=\"1\"/>MESSAGE BOX:
								</td>
							</tr>
						</table>
					</td>
					<td valign=\"top\" rowspan=\"2\">
				 		<table>
				 			<!-- 
				 			<tr bgcolor=\"#00FF00\">
				 				<td 
				 					align=\"center\" 
				 					style=\"border-collapse : collapse; border : 1px solid black;\">				 						
				 						<font size=\"4\">LOADING</font>
				 				</td>
				 			</tr>
				 			-->
				 			<tr><td align=\"center\"><font size=\"1.75\"/>STEP COMPLETION</td></tr>
				 			<tr>
				 				<td align=\"center\">
				 					<font 				 						
				 						size=\"2\" 
				 						style=\"font-style: italic;\">
				 							<label 
				 								id=\"stepCompletion_#{slotLabel2Param}\">
				 									#{getStepCompletion()}
				 							</label>
				 					</font>
				 				</td>
				 			</tr>
				 			<tr>
				 				<td>
				 					<hr>
				 				</td>
				 			</tr>
				 			<tr>
				 				<td align = \"center\">
				 					<button 
										onclick=\"window.location='/TopBtnPressed?slot=#{slotLabel2Param}&BtnState=#{getButtonDisplay(slotLabel2Param)}'\"
										type=\"button\" 
				 						style=\"width:100;height:25\" 
				 						id=\"btn_#{slotLabel2Param}\"
				 						>
				 							#{getButtonDisplay(slotLabel2Param)}
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
									<center>
									<font size=\"1.25\" style=\"font-style: italic;\">#{GetSlotFileName()}</font>"
		if GetSlotFileName() != BlankFileName
		topTable+= "	<button 
							style=\"height:20px; width:50px; font-size:10px\" 							
							onclick=\"window.location='../ViewFile?File=#{GetSlotFileName()}'\" />
							View
									</button>"									
		end									

		topTable += "								
									</center>
								</td>
							</tr>
							<tr>
								<td align=\"left\">
										<font size=\"1\">Step Duration (HH:MM):</font>
								</td>
							</tr>
							<tr>
								<td align = \"center\">
									<font size=\"1.25\" style=\"font-style: italic;\">
										#{GetSlotDurationHours()}:#{GetSlotDurationMins()}
									</font>								
								</td>
							</tr>
							<tr>
								<td align=\"left\">
										<font size=\"1\">Duration Left:</font>
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
											#{GetDurationLeft()}
										</label>
										<input 
											type=\"hidden\"
											name=\"hiddenTimeOfRun_#{slotLabel2Param}\"
											value=\"#{getSlotProperties()[TimeOfRun].to_i}\" />
										<input 
											type=\"hidden\"
											name=\"hiddenDurationLeft_#{slotLabel2Param}\"
											value=\"#{GetSlotDurationHoursLeft()}:#{GetSlotDurationMinsLeft()}:#{GetSlotDurationSecsLeft()}\" />
									</font>
								</td>
							</tr>
							<tr>
								<td>
								</td>
							</tr>
				 			<tr>
				 				<td align=\"center\">"
				 				
				 				if getButtonDisplay(slotLabel2Param) == Run	
				 					topTable+=				 					
				 						"
				 					<button 
										onclick=\"window.location='/TopBtnPressed?slot=#{slotLabel2Param}&BtnState=Clear'\"
										type=\"button\" 
				 						style=\"width:100;height:25\" 
				 						id=\"btn_LoadStartStop\"
				 						>
				 							#{Clear}
				 					</button>"
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
		displayForm = ""
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
	function updateCountDowns() {
	/*
		For the blinky blinky
		updateBtnColor(\"SLOT1\",ct);
		if (ct>3) {
			ct = 0;
	*/
			updateCountDownsSub(\"SLOT1\");
			updateCountDownsSub(\"SLOT2\");
			updateCountDownsSub(\"SLOT3\");
/*
		}
		ct++;
*/					
	}
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
	function updateCountDownsSub(SlotParam) {
		var btnSlot1 = document.getElementById(\"btn_\"+SlotParam).innerHTML;
		btnSlot1 = btnSlot1.trim();
			var durationLeftHidden = document.getElementsByName(\"hiddenDurationLeft_\"+SlotParam)
			durationLeftHidden = durationLeftHidden[0];
			durationLeft = durationLeftHidden.value.trim();
			
			/*
				Reverse parsing, get the seconds, then the minutes, then the hours.  The goal is to get the total time
				and add it to the current time to show that the 'Step Completion' is moving forward while it's not in
				play mode.
			*/
			var colonBeforeSeconds = durationLeft.lastIndexOf(\":\");
			var secondsLeft = durationLeft.substring((colonBeforeSeconds+1),durationLeft.length);
			var seconds = parseInt(secondsLeft);
			var hoursAndMins = durationLeft.substring(0,colonBeforeSeconds);
			
			var colonBeforeMin = hoursAndMins.lastIndexOf(\":\");
			var minsLeft = durationLeft.substring((colonBeforeMin+1),hoursAndMins.length);
			var minutes = 60*parseInt(minsLeft);

			var hoursLeft = durationLeft.substring(0,colonBeforeMin);
			var hours = 60*60*parseInt(hoursLeft);

			var sc;
			var timeOfRun = 0;
			if (btnSlot1 == \"#{Stop}\") {
				sc = document.getElementsByName(\"hiddenTimeOfRun_\"+SlotParam);			
				timeOfRun = parseInt(sc[0].value)*1000;
				sc.innerHTML = stepCompletionDisplay;
			}					
			
			var currentdate = new Date();
			var stepCompletion = new Date(currentdate.getTime() + (hours+minutes+seconds)*1000);
			var stepCompletionDisplay = 
				(stepCompletion.getMonth()+1) + \"/\" + 
				stepCompletion.getDate() + \"/\" + 
				stepCompletion.getFullYear() + \"  \" + 
				stepCompletion.getHours() + \":\" + 
				stepCompletion.getMinutes() + \":\" + stepCompletion.getSeconds();
				
		if (btnSlot1 == \"#{Run}\") {
			sc = document.getElementById(\"stepCompletion_\"+SlotParam);			
			sc.innerHTML = stepCompletionDisplay;
		}
		else if (btnSlot1 == \"#{Stop}\") {
			var diff = (hours+minutes+seconds)*1000-(currentdate.getTime()-timeOfRun);
			hours = Math.floor(diff / (1000 * 60 * 60));
			diff -= hours * (1000 * 60 * 60);

			mins = Math.floor(diff / (1000 * 60));
			diff -= mins * (1000 * 60);

			seconds = Math.floor(diff / (1000));
			diff -= seconds * (1000);
			sc = document.getElementById(\"durationLeft_\"+SlotParam);			
			sc.innerHTML = \"\"+hours+\":\"+mins+\":\"+seconds
		}		
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
	
	setInterval(function(){loadXMLDoc()},10000); 
	setInterval(function(){updateCountDowns()},1000); 
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
						<font size=\"3\">Step Files</font><br>"
		#
		# Create a list of Test Files, and display them in a table.
		# 						
		repoDir = "file\ repository"
		# files = Dir["#{repoDir}/*.step"]
		files = getListOfFiles("#{repoDir}","*.step")
		tbr += "<table style=\"border-collapse: collapse;	border: 1px solid black;\">"
		fileIndex = 0;
		totalColumns = 0
		rowItems = ""
		while fileIndex< files.length
			rowItems += "<td style=\"border: 1px solid black;\">&nbsp;
																	<button 
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
						<font size=\"1\">&nbsp;[&nbsp;Expected file fxtensions: *.step - for Step file;&nbsp;&nbsp;*.ps_config - for Power Supply sequence file;&nbsp;&nbsp;*.temp_config - for Temperature setting file.]</font>
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
			if configFileType == PSSeqFileTemplate
				configTemplateRows = psConfigFileTemplate.split("\n")
			elsif configFileType == StepFileTemplate
				configTemplateRows = stepConfigFileTemplate.split("\n")
			else
				configTemplateRows = tempConfigFileTemplate.split("\n")
			end
			rowCt = 0
			maxColCt = getMaxColCt(configTemplateRows)
			
			tbr += "<center>Below is a sample configuration template.  Column Name must be on column 'C',"
			tbr += " and data must be in this given order and format.  Do not use comma in the data.</center><br><br>"
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
	
	def is_a_number?(s)
  	s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
	end

	def getKnownRowNamesFor(fileTypeParam)
		if @lastKnownFileType != fileTypeParam
			@lastKnownFileType == fileTypeParam
			@knownConfigRowNames = Hash.new
			@hashUniqueIndex = Hash.new
			if fileTypeParam == UserInterface::PSSeqFileTemplate				
				configTemplateRows = psConfigFileTemplate.split("\n")
			elsif fileTypeParam  == UserInterface::TempSetTemplate							
				configTemplateRows = tempConfigFileTemplate.split("\n")
			end
			rowCt = 0
			while rowCt<configTemplateRows.length do
				columns = configTemplateRows[rowCt].split(",")
				colName = columns[2].to_s.upcase
				@knownConfigRowNames[colName] = "nn" # nn - not nil.
				rowCt += 1
			end
		end
		
		return @knownConfigRowNames
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
				is_a_number?(valueParam) == false)
			@redirectWithError+="&ErrIndex=#{indexParam}&ErrColType=#{colnameParam}"
			@redirectWithError+="&ErrValue="+SharedLib.makeUriFriendly("#{valueParam}")
			return @redirectWithError
		elsif colnameParam == IndexCol
			#
			# Make sure that the index is unique, and not repeated.
			#
			if valueParam.length>0 && colnameParam==UserInterface::IndexCol
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
		if getSlotProperties()[stepNameParam].nil? == true
			getSlotProperties()[stepNameParam] = Hash.new
		end
		
		return getSlotProperties()[stepNameParam]				
	end
	
	def clearInternalSettings
		getSlotProperties()[FileName] = ""
		getSlotProperties()[DurationHours] = "00"
		getSlotProperties()[DurationHoursLeft] = "00"
		getSlotProperties()[DurationMins] = "00"
		getSlotProperties()[DurationMinsLeft] = "00"
		getSlotProperties()[DurationSecsLeft] = "00"
	end
	
	def setItemParameter(nameParam, param, valueParam)
		#
		# Get the value as data for processing the slot.
		#
		if getSlotConfigStep(stepName)[configFileType].nil? == true
			getSlotConfigStep(stepName)[configFileType] = Hash.new
		end		
		
		if getSlotConfigStep(stepName)[configFileType][nameParam].nil?
			getSlotConfigStep(stepName)[configFileType][nameParam] = Hash.new
		end
		
		getSlotConfigStep(stepName)[configFileType][nameParam][param] = valueParam

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
	
	def setBbbToStopMode()
		@response = 
      RestClient.post "http://192.168.7.2:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::StopFromPC}" }.to_json, :content_type => :json, :accept => :json
	end
	
	def setToRunMode()
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
		getSlotProperties()[ButtonDisplay] = Stop
		@response = 
      RestClient.post "http://192.168.7.2:8000/v1/pclistener/", {PcToBbbCmd:"#{SharedLib::RunFromPC}" }.to_json, :content_type => :json, :accept => :json
	end	

	def parseTheConfigFile(config,configFileName)
		#
		# We got to parse the data.  Make sure that the data format is what Mike had provided by ensuring 
		# that the column
		# item matches the known rows.
		#
		
		#
		# The following are the known rows
		# Ideally, get the the known row names from the template above vice having a separate column names here.
		#
		if @configFileType == UserInterface::StepFileTemplate
			#
			# We're going to parse a step file.  Hard code settings:  "Item","Name","Description","Type","Value" are
			# starting on row 2, col A if viewed from Excel.
			#
			row = 1
			colContent = config[row].split(",")
			if (colContent[0].upcase.strip != "ITEM")
				@redirectWithError += "&ErrStepFormat=A"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
				return false
			elsif (colContent[1].upcase.strip != "NAME")
				@redirectWithError += "&ErrStepFormat=B"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
				return false
			elsif (colContent[2].upcase.strip != "DESCRIPTION")
				@redirectWithError += "&ErrStepFormat=C"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
				return false
			elsif (colContent[3].upcase.strip != "TYPE")
				@redirectWithError += "&ErrStepFormat=D"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
				return false
			elsif (colContent[4].upcase.strip != "VALUE")
				@redirectWithError += "&ErrStepFormat=E"
				@redirectWithError += "&ErrInFile=#{SharedLib.makeUriFriendly(uploadedFileName)}"
				return false
			end
			
			#
			# Make sure that the step file has no two equal step names 
			#			
			uniqueStepNames = Hash.new
			ct = 2
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
			ct = 3
			while ct < config.length do
				@stepName = config[ct-1].split(",")[2].strip # Get the row data for file name.
				colContent = config[ct].split(",")[2].strip
				if colContent.nil? == true || colContent.length == 0
					@redirectWithError += "&ErrInFile="
					@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
					@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(stepName)}"
					@redirectWithError += "&ErrPsFileNotGiven=Y"
					@redirectWithError = SharedLib.makeUriFriendly(@redirectWithError)
					return false
				else
					#
					# Make sure that the PS config file is present in the file system
					#
					if File.file?(dirFileRepository+"/"+colContent) == false
						#
						# The file does not exists.  Post an error.
						#
						@redirectWithError += "&ErrInFile="
						@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
						@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(stepName)}"
						@redirectWithError += "&ErrStepPsNotFound=#{SharedLib.makeUriFriendly(colContent)}"
						return false
					else 
						#
						# Make sure the PS File config is good.
						#
						@configFileType = UserInterface::PSSeqFileTemplate
						if checkFaultyPsOrTempConfig(colContent,"#{__LINE__}-#{__FILE__}") == false
							return false
						end
					end
				end
				ct += 11
			end

			
			#
			# Make sure the Temp Config file is given
			#
			ct = 4
			while ct < config.length do
				@stepName = config[ct-2].split(",")[2].strip # Get the row data for the step file name.
				colContent = config[ct].split(",")[2].strip
				if colContent.nil? == true || colContent.length == 0
					fromHere = "#{__LINE__}-#{__FILE__}"
					@redirectWithError += "&ErrInFile="
					@redirectWithError += "#{SharedLib.makeUriFriendly(configFileName)}"
					@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(stepName)}"
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
						@redirectWithError += "&ErrInStep=#{SharedLib.makeUriFriendly(stepName)}"
						@redirectWithError += "&ErrStepTempNotFound=#{SharedLib.makeUriFriendly(colContent)}"
						return false
					else 
						#
						# Make sure the Temp File config is good.
						#
						@configFileType = UserInterface::TempSetTemplate
						if checkFaultyPsOrTempConfig(colContent,"#{__LINE__}-#{__FILE__}") == false
							return false
						end
					end
				end
				ct += 11
			end
						
			#
			# Make sure 'STEP TIME', 'Temp Wait Time', 'Alarm Wait Time' are numbers
			#			
			if mustBeNumber(configFileName,6,config,"Step Time") == false
					return false
			end
			
			if mustBeNumber(configFileName,7,config,"TEMP WAIT") == false
					return false
			end
			
			if mustBeNumber(configFileName,8,config,"Alarm Wait") == false
					return false
			end
			
			#
			# Make sure that 'Auto Restart' and 'Stop on Tolerance' are boolean (1 or 0)
			#
			if mustBeBoolean(configFileName,9,config,"Auto Restart") == false
					return false
			end
			
			if mustBeBoolean(configFileName,10,config,"Stop on Tolerance") == false
					return false
			end
			
			#
			# Get the sequence up and sequence down of power supplies
			#
			
		elsif @configFileType == UserInterface::PSSeqFileTemplate ||
					@configFileType == UserInterface::TempSetTemplate
			@redirectWithError = "/TopBtnPressed?slot=#{getSlotOwner()}"
			@redirectWithError += "&BtnState=#{@Load}"
			if checkFaultyPsOrTempConfig("#{configFileName}",
				"#{__LINE__}-#{__FILE__}") == false				
				return false
			end
			@redirectWithError += "&MsgFileUpload=#{SharedLib.makeUriFriendly(configFileName)}"
			return false
		end		
		
		return true
		# End of def parseTheConfigFile(config)
	end

	def checkFaultyPsOrTempConfig(fileNameParam,fromParam)		
		#
		# Returns true if no fault, false if there is error
		#
		config = Array.new
		File.open("#{dirFileRepository}/#{fileNameParam}", "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
		
		knownRowNames = getKnownRowNamesFor(configFileType)			
		#
		# Make sure that each row have a column name that is found within the template which Mike provided.
		#
		ct = 0
		while ct < config.length do
			colContent = config[ct].split(",")[2].upcase
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
		indexCol = 1
		nameCol = 2
		unitCol = 4
		nomSetCol = 5
		tripMinCol = 6
		tripMaxCol = 7
		flagTolPCol = 8 # Flag Tolerance Positive
		flagTolNCol = 9 # Flag Tolerance Negative
		enableBitCol = 10 # Flag indicating that software can turn it on or off
		idleStateCol = 11 # Flag indicating that software can turn it on or off
		loadStateCol = 12 # Flag indicating that software can turn it on or off
		startStateCol = 13 # Flag indicating that software can turn it on or off
		runStateCol = 14 # Flag indicating that software can turn it on or off
		stopStateCol = 15 # Flag indicating that software can turn it on or off
		clearStateCol = 16 # Flag indicating that software can turn it on or off
		locationCol = 17 # Flag indicating that software can turn it on or off

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
			stopState = columns[stopStateCol].upcase
			clearState = columns[clearStateCol].upcase

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
					else					
						if "TIME".upcase == name
							setDurationHours("00");
							setDurationMinutes(nomSet);
						end
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
				
				if unit == "V" || unit == "A" || unit == "C" || unit == "M"
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
		seqUpCol = 6
		seqUpDlyMsCol = 7
		seqDownCol = 8
		seqDownDlyMsCol = 9
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
								
			end
			ct += 1
			# End of 'while ct < config.length do'
		end
		return true
		# End of 'checkFaultyPsOrTempConfig'	
	end
	
	def setupBbbSlotProcess(fileNameParam)
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
		setTimeOfUpload()
		setToAllowedToRunMode()
		saveSlotState()
		PP.pp(slotProperties)
		return true
	end
	
	def emptyOrNotNumberTest(indexCol,fileNameParam,columns,indexParam, colNumParam,colNameParam)
		if columns[colNumParam].nil? || SharedLib.isInteger(columns[colNumParam]) == false	
			#
			# the indicated data is not a valid numbers.
			#
			error = "Error: In file '#{SharedLib.makeUriFriendly(fileNameParam)}', #{colNameParam} column"
			error += " on index '#{columns[indexCol]}' must be an integer."
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
	
		stepFile = uploadedFileName[uploadedFileName.length-stepFileExtension.length..-1]
		psFile  = uploadedFileName[uploadedFileName.length-psFileExtension.length..-1]
		tempFile = uploadedFileName[uploadedFileName.length-temperatureFileExtension.length..-1]
		
		if stepFile == stepFileExtension
			@configFileType = UserInterface::StepFileTemplate
		elsif psFile == psFileExtension
			@configFileType = UserInterface::PSSeqFileTemplate
		elsif tempFile == temperatureFileExtension
			@configFileType = UserInterface::TempSetTemplate
		else
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

post '/ViewFile' do
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
	if params[:File].nil? == false
		#
		# Setup the string for error
		#
		settings.ui.redirectWithError = "/TopBtnPressed?slot=#{settings.ui.getSlotOwner()}"
		settings.ui.redirectWithError += "&BtnState=#{settings.ui.Load}"	
		
		uploadedFileName = "#{params[:File]}"
		if settings.ui.setConfigFileType(uploadedFileName) == false
			redirect settings.ui.redirectWithError
		end
	
		if settings.ui.setupBbbSlotProcess("#{params[:File]}") == false
				redirect settings.ui.redirectWithError
		end
		redirect "../"
	else
		settings.ui.setSlotOwner("#{SharedLib.uriToStr(params[:slot])}")
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
				settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Step file format is incorrect.  Column labels must start on column A, row 2."
			elsif (SharedLib.uriToStr(params[:ErrGeneral]).nil? == false && SharedLib.uriToStr(params[:ErrGeneral]) != "")
				if SharedLib.uriToStr(params[:ErrGeneral]) == "FileNotKnown"	
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', Unknown file extension.  Must be one of these: *.step, *.ps_config, or *.temp_config"
				elsif SharedLib.uriToStr(params[:ErrGeneral]) == "bbbDown"
					settings.ui.upLoadConfigErrorGeneral = "File '#{SharedLib.uriToStr(params[:ErrInFile])}', BBB PcListener is down.  Need to handle this in production code level."
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
			settings.ui.setToRunMode()
			settings.ui.setTimeOfRun()
			settings.ui.saveSlotState();
			redirect "../"
		elsif SharedLib.uriToStr(params[:BtnState]) == settings.ui.Stop
			#
			# The Stop button got pressed.
			#
			settings.ui.setBbbToStopMode()
			settings.ui.setToAllowedToRunMode()
			settings.ui.setTimeOfStop()
		
			#
			# Update the duration time
			# Formula : Time now - Time of run, then convert to hours, mins, sec.
			#
			settings.ui.updateDurationTimeLeft()
			settings.ui.saveSlotState();
			redirect "../"
		elsif SharedLib.uriToStr(params[:BtnState]) == settings.ui.Clear
			#
			# The Clear button got pressed.
			#
			settings.ui.setToLoadMode()
			settings.ui.setTimeOfClear()
			settings.ui.saveSlotState();
			redirect "../"
		end
	end
end

get '/' do 
	return settings.ui.display
end

post '/' do	
	settings.ui.saveSlotState() # Saves the state everytime the display gets refreshed.  10 second resolution...
	return settings.ui.display
end



post '/TopBtnPressed' do
	if settings.ui.slotOwnerThe.nil? || settings.ui.slotOwnerThe == ""
		settings.ui.getSlotsState
		redirect "../"
	end
	settings.ui.clearError()
	settings.ui.clearInternalSettings();

	tbr = "" # To be returned.
	
	#
	# Make sure that the "file repository" directory exists.
	#
	dirFileRepository = "file repository"
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

	#
	# Find out what type of file we're dealing with:
	# *.step - for Step file
	# *.ps_config - for Power Supply sequence file
	# *.temp_config - for Temperature setting file.
	#
	uploadedFileName = "#{params['myfile'][:filename]}"
	if settings.ui.setConfigFileType(uploadedFileName) == false
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
		if settings.ui.setupBbbSlotProcess("#{params['myfile'][:filename]}") == false
				redirect settings.ui.redirectWithError
		end
	end  
  
	settings.ui.setBbbConfigUpload()
	
  redirect "../"
end


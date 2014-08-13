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
  send_file('/root/dev/notes/images/'+params[:file], :disposition => 'inline')
end
=end
# Code to look at:
# "The run duration is complete."
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'json'

class UserInterface
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
	Location = "Location"
	
	attr_accessor :slotProperties
	attr_accessor :upLoadConfigErrorName
	attr_accessor :upLoadConfigErrorRow
	attr_accessor :upLoadConfigErrorIndex
	attr_accessor :upLoadConfigErrorCol
	attr_accessor :upLoadConfigErrorColType
	attr_accessor :upLoadConfigErrorValue
	attr_accessor :knownConfigRowNames

	def setSlotOwner(slotOwnerParam)
		@slotOwnerThe = slotOwnerParam
	end

	def getSlotOwner
		if @slotOwnerThe.nil? || @slotOwnerThe == ""
			puts "Calling getSlotsState #{__LINE__}-#{__FILE__}"
			getSlotsState
			puts "Calling - redirect \"../\" #{__LINE__}-#{__FILE__}"
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

	def configFileTemplate
		return "
			,,,,,,,,,,,,,,,,,
			,,,,,,,,,,,,,,,,,
			,Config File,,,,,,,,,,Condition,,,,,,
			,,,,,Nom,Trip,Trip,FLAG,FLAG,Enable,IDLE,LOAD,START,RUN,STOP,CLEAR,
			,index,Name,Type,Unit,SET,MIN,MAX,Tol+,Tol-,BIT,,,,,,,
			,1,P12V,Controller PS Voltage,V,12,10.8,13.2,11.4,12.6,,ON,ON,ON,ON,ON,ON,
			,2,IP12V,Controller PS Current,A,6,0,15,5.7,6.3,,,,,,,,
			,3,P24V,Controller PS Voltage,V,24,21.6,26.4,22.8,25.2,,ON,ON,ON,ON,ON,ON,
			,4,IP24v,Controller PS Current,A,20,0,60,19,21,,,,,,,,
			,5,SLOT P5V,Controller PS Voltage,V,5,4.5,5.5,4.75,5.25,,ON,ON,ON,ON,ON,ON,
			,6,IP5V,Controller PS Current,A,1,0,5,0.95,1.05,,,,,,,,
			,7,SLOT P3V3,Controller PS Voltage,V,3.3,2.97,3.63,3.135,3.465,,ON,ON,ON,ON,ON,ON,
			,8,SLOT P1V8,Controller PS Voltage,V,1.8,1.62,1.98,1.71,1.89,,ON,ON,ON,ON,ON,ON,
			,9,BIB P5v,Slot PS Voltage,V,5,4.5,5.5,4.75,5.25,YES,OFF,SEQUP,ON,ON,ON,SEQDN,Slot PCB
			,10,BIB P12V,Slot PS Voltage,V,12,10.8,13.2,11.4,12.6,YES,OFF,SEQUP,ON,ON,ON,SEQDN,Slot PCB
			,11,BIB N5v,Slot PS Voltage,V,-5,-4.5,-5.5,-4.75,-5.25,YES,OFF,SEQUP,ON,ON,ON,SEQDN,Slot PCB
			,12,CALREF,Slot Ref Voltage,V,1.2,1.08,1.32,1.14,1.26,,ON,ON,ON,ON,ON,ON,
			,13,SLOT TEMP1 SENSR,Slot Temperatrure sensor,C,65,22,81.25,61.75,68.25,,ON,ON,ON,ON,ON,ON,
			,14,SLOT TEMP2 SENSR,Slot Temperatrure sensor,C,65,22,81.25,61.75,68.25,,ON,ON,ON,ON,ON,ON,
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
			,38,TDUT,DUT TEMPERATURE [1:24],C,125,25,135,118.75,131.25,YES,OFF,OFF,ON,ON,OFF,OFF,
			,39,TIME,STEP TIME,M,2400,0,2640,,2520,,,,,,,,
			,40,TEMP WAIT,WAIT TIME ON TEMPERATURE,M,10,0,11,,10.5,,,,,,,,
			,41,Auto Restart,Auto restart,B,1,,,,,,,,,,,,
			,42,Stop on Tolerance,Stop on tolerance limit,B,0,,,,,,,,,,,,
			,43,Step Name,Step Name,T,STRING,,,,,,,,,,,,
			,44,Next Step,Next Step Name,T,STRING,,END,,,,,,,,,,
			,45,Text Vector,Test Vector Name & Path,T,STRING,,,,,,,,,,,,"
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
				puts "getSlotProperties()[TimeOfRun]=#{getSlotProperties()[TimeOfRun]}"
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
		# puts "slotProperties.to_json.nil?=#{slotProperties.to_json.nil?}"
		# puts "slotProperties.to_json='#{slotProperties.to_json}'"
		if slotProperties.to_json == "{}"
			# puts "calling - getSlotsState()"
			getSlotsState()
		end		
		# puts "slotProperties.to_json=#{slotProperties.to_json}"
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
										onclick=\"window.location='../TopBtnPressed?slot=#{slotLabel2Param}&BtnState=#{getButtonDisplay(slotLabel2Param)}'\"
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
										<font size=\"1\">Config File Name:</font>
								</td>
							</tr>
							<tr>
								<td>
									<center>
									<font size=\"1.25\" style=\"font-style: italic;\">#{GetSlotFileName()}</font>								
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
										onclick=\"window.location='../TopBtnPressed?slot=#{slotLabel2Param}&BtnState=Clear'\"
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
	
	def loadFile
		#
		# tbr - to be returned
		#
		tbr = "
		<html>
			<body>
					<form 
						action=\"/TopBtnPressed?slot=#{getSlotOwner()}\" 
						method=\"post\" 
						enctype=\"multipart/form-data\">
						<font size=\"3\">Configuration File Uploader</font>"
		if (upLoadConfigErrorRow.nil? == false && upLoadConfigErrorRow.length > 0) ||
			 (upLoadConfigErrorIndex.nil? == false && upLoadConfigErrorIndex.length > 0)
			if upLoadConfigErrorColType.nil? == false && upLoadConfigErrorColType.length > 0
				
				case upLoadConfigErrorColType
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
				tbr += "<font color=\"red\">Configuration File Error : "
				tbr += "Value '#{upLoadConfigErrorValue}' on Index (#{upLoadConfigErrorIndex}), '#{errorType}' column expects a numer.<br><br>"
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
						<br>
						<br>
						"
						

		if (upLoadConfigErrorRow.nil? == false && upLoadConfigErrorRow.length > 0) ||
			 (upLoadConfigErrorIndex.nil? == false && upLoadConfigErrorIndex.length > 0)
			#
			# There's an error, show it to the user.
			#

			#
			# Get the max column in the template so we could draw our table correcty
			#
			configTemplateRows = configFileTemplate.split("\n")
			rowCt = 0
			maxColCt = 0
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
			
			tbr += "<center>Below is a sample configuration template.  Column Name must be on column 'C',"
			tbr += " and data must be in this given order and format.  Do not use comma in the data.</center><br><br>
				<table width=\"100%\">
					<tr>
						<td align=\"center\">
							<center>
							<table style=\"border-collapse: collapse;\">"
						configTemplateRows = configFileTemplate.split("\n")
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
		tbr += "
					</form>
			</body>
		</html>
		"
		
		return tbr
		# end of 'def loadFile'
	end	
	
	def is_a_number?(s)
  	s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
	end
	
	def getKnownRowNames
		#
		#	Returns the known row names of the configuration file.
		#
		if @knownConfigRowNames.nil?
			@knownConfigRowNames = Hash.new
			configTemplateRows = configFileTemplate.split("\n")
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
	
	def checkConfigValue(valueParam, colnameParam, indexParam)
		if (is_a_number?(valueParam) == false)
			puts "Failed number test. #{__LINE__}-#{__FILE__}"
			redirectWithError = "../TopBtnPressed?slot=#{getSlotOwner()}&BtnState=#{Load}"
			redirectWithError += "&ErrIndex=#{indexParam}&ErrColType=#{colnameParam}&ErrValue=#{valueParam}"
			return redirectWithError
		else
			return ""
		end
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
		puts "setItemParameter nameParam=#{nameParam}, param=#{param}, valueParam=#{valueParam} #{__LINE__}-#{__FILE__}"
		puts "getSlotProperties()[nameParam].nil? = #{getSlotProperties()[nameParam].nil?}"
		puts "getSlotProperties()[nameParam] = #{getSlotProperties()[nameParam]}"
		puts " #{__LINE__}-#{__FILE__}"
		if getSlotProperties()[nameParam].nil?
			puts "A #{__LINE__}-#{__FILE__}"
			getSlotProperties()[nameParam] = Hash.new
			puts "B #{__LINE__}-#{__FILE__}"
		end
		puts "C #{__LINE__}-#{__FILE__}"
		getSlotProperties()[nameParam][param] = valueParam
		puts "D #{__LINE__}-#{__FILE__}"

		# End of 'def setItemParameter(nameParam, param, valueParam)'
	end

	def setDataSetup(
					nameParam,unitParam,nomSetParam,tripMinParam,tripMaxParam,flagTolPParam,flagTolNParam,enableBitParam,
					idleStateParam,loadStateParam,startStateParam,runStateParam,stopStateParam,clearStateParam,locationParam
				)
		puts "setDataSetup function got called. #{__LINE__}-#{__FILE__}"
		puts "SlotOwner = '#{getSlotOwner()}' #{__LINE__}-#{__FILE__}"
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
		setItemParameter(nameParam,Location,locationParam)
		# End of 
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
	end	
	
	# End of class UserInterface
end

set :ui, UserInterface.new
set :port, 2679 # orig 4569

get '/about' do
	'A little about me.'
end

get '/TopBtnPressed' do
	settings.ui.setSlotOwner("#{params[:slot]}")
	if params[:BtnState] == settings.ui.Load
		#
		# The Load button got pressed.
		#
		puts "check #{__LINE__}-#{__FILE__}"
		if (params[:ErrRow].nil? == false && params[:ErrRow] != "") || 
			 (params[:ErrIndex].nil? == false && params[:ErrIndex] != "")
			puts "check #{__LINE__}-#{__FILE__}"
			settings.ui.upLoadConfigErrorIndex = params[:ErrIndex]
			settings.ui.upLoadConfigErrorRow = params[:ErrRow]
			settings.ui.upLoadConfigErrorCol = params[:ErrCol]
			settings.ui.upLoadConfigErrorName = params[:ErrName]
			settings.ui.upLoadConfigErrorColType = params[:ErrColType]
			settings.ui.upLoadConfigErrorValue = params[:ErrValue]
		else
			puts "check #{__LINE__}-#{__FILE__}"
			settings.ui.upLoadConfigErrorName = ""
		end
		
		puts "check #{__LINE__}-#{__FILE__}"
		return settings.ui.loadFile
	elsif params[:BtnState] == settings.ui.Run
		#
		# The Run button got pressed.
		#
		settings.ui.setToRunMode()
		settings.ui.setTimeOfRun()
		settings.ui.saveSlotState();
		redirect "../"
	elsif params[:BtnState] == settings.ui.Stop
		#
		# The Stop button got pressed.
		#
		settings.ui.setToAllowedToRunMode()
		settings.ui.setTimeOfStop()
		
		#
		# Update the duration time
		# Formula : Time now - Time of run, then convert to hours, mins, sec.
		#
		settings.ui.updateDurationTimeLeft()
		settings.ui.saveSlotState();
		redirect "../"
	elsif params[:BtnState] == settings.ui.Clear
		#
		# The Clear button got pressed.
		#
		settings.ui.setToLoadMode()
		settings.ui.setTimeOfClear()
		settings.ui.saveSlotState();
		redirect "../"
	end	
end

get '/' do 
	puts "get / got called."
	return settings.ui.display
end

post '/' do	
	puts "post / got called."
	settings.ui.saveSlotState() # Saves the state everytime the display gets refreshed.  10 second resolution...
	return settings.ui.display
end

post '/TopBtnPressed' do
	settings.ui.clearError()
	settings.ui.clearInternalSettings();

	tbr = "" # To be returned.
	
	#
	# Save the file in the upload folder.
	#
	goodUpload = true
	File.open('uploads/configuration.csv' , "w") do |f|
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
		config = Array.new
		File.open('uploads/configuration.csv', "r") do |f|
			f.each_line do |line|
				config.push(line)
			end
		end
		
		#
		# We got to parse the data.  Make sure that the data format is what Mike had provided by ensuring that the column
		# item matches the known rows.
		#
		
		#
		# The following are the known rows
		# Ideally, get the the known row names from the template above vice having a separate column names here.
		#
		knownRowNames = settings.ui.getKnownRowNames
		
		#
		# Setup the string for error
		#
		redirectWithError = "../TopBtnPressed?slot=#{settings.ui.getSlotOwner()}&BtnState=#{settings.ui.Load}"


		#
		# Make sure that each row have a column name that is found within the template which Mike provided.
		#
		ct = 0
		while ct < config.length do
			colContent = config[ct].split(",")[2].upcase
			# puts "colContent='#{colContent}'"
			if colContent.length>0 && (knownRowNames[colContent].nil? || knownRowNames[colContent] != "nn")
				#
				# How are we going to inform the user that the file is not a good one?
				#
				redirectWithError += "&ErrRow=#{(ct+2)}&ErrCol=3&ErrName=#{colContent}"
				redirect redirectWithError
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
			location = columns[locationCol].upcase

=begin			
			puts "name=#{name} #{__LINE__}-#{__FILE__}"
			puts "unit=#{unit} #{__LINE__}-#{__FILE__}"			
			puts "nomSet=#{nomSet} #{__LINE__}-#{__FILE__}"
			puts "tripMin=#{tripMin} #{__LINE__}-#{__FILE__}"
			puts "tripMax=#{tripMax} #{__LINE__}-#{__FILE__}"
			puts "flagTolP=#{flagTolP} #{__LINE__}-#{__FILE__}"
			puts "flagTolN=#{flagTolN} #{__LINE__}-#{__FILE__}"
			puts "  -----------------  #{__LINE__}-#{__FILE__}"
=end
			if skipNumCheckOnRows[name].nil?
				#
				# The row with the given name is not to be skipped.
				#
				if unit == "M"
					#
					# Make sure that the following items -  nomSet,tripMin, tripMax, flagTolP, flagTolN are numbers
					#					
					error = settings.ui.checkConfigValue(nomSet,"nomSetCol",columns[1])
					if error.length > 0
						redirect error
					else					
						if "TIME".upcase == name
							puts "in here -\"TIME\".upcase == name- #{__LINE__}-#{__FILE__}"
							puts "nomSet = #{nomSet} #{__LINE__}-#{__FILE__}"
							settings.ui.setDurationHours("00");
							settings.ui.setDurationMinutes(nomSet);
						end
					end
					# End of 'if unit == "M"'
				elsif unit == "V" || unit == "A" || unit == "C"
					#
					# Make sure that the following items -  nomSet,tripMin, tripMax, flagTolP, flagTolN are numbers
					#					
					error = settings.ui.checkConfigValue(nomSet,"nomSetCol",columns[1])
					if error.length > 0
						redirect error
					end
					
					error = settings.ui.checkConfigValue(tripMin,"tripMinCol",columns[1])
					if error.length > 0
						redirect error
					end
					
					error = settings.ui.checkConfigValue(tripMax,"tripMaxCol",columns[1])
					if error.length > 0
						redirect error
					end
					
					error = settings.ui.checkConfigValue(flagTolP,"flagTolPCol",columns[1])
					if error.length > 0
						redirect error
					end
					
					error = settings.ui.checkConfigValue(flagTolN,"flagTolNCol",columns[1])
					if error.length > 0
						redirect error
					end					
					# End of 'elsif unit == "V" || unit == "A" || unit == "C"'
				end								
				#
				# Get the data for processing
				#
				settings.ui.setDataSetup(
					name,unit,nomSet,tripMin,tripMax,flagTolP,flagTolN,enableBit,idleState,
					loadState,startState,runState,stopState,clearState,location
				)
				# end of 'if skipNumCheckOnRows[name].nil?'
			end
			
			
			# puts "colContent='#{colContent}'"
			if colContent.length>0 && (knownRowNames[colContent].nil? || knownRowNames[colContent] != "nn")
				#
				# How are we going to inform the user that the file is not a good one?
				#
				redirectWithError = "../TopBtnPressed?slot=#{settings.ui.getSlotOwner()}&BtnState=#{settings.ui.Load}"
				redirectWithError += "&ErrRow=#{ct+1}&ErrCol=3&ErrName=#{colContent}"
				redirect redirectWithError
			end
			ct += 1
		end
		
		settings.ui.setConfigFileName("#{params['myfile'][:filename]}")
		settings.ui.setTimeOfUpload()
		settings.ui.setToAllowedToRunMode()
		settings.ui.saveSlotState()
  end  
  redirect "../"
end


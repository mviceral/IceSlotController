# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
# Code to look at:
# "The run duration is complete."
require 'rubygems'
require 'sinatra'
require 'sqlite3'
require 'json'

class UserInterface
	BlankFileName = "-----------"
	FileName = "FileName"
	Load = "Load"
	Run = "Run"
	Stop = "Stop"
	Clear = "Clear"
	DurationHours = 	"DurationHours"
	DurationMins = "DurationMins"
	DurationHoursLeft = 	"DurationHoursLeft"
	DurationMinsLeft = "DurationMinsLeft"
	DurationSecsLeft = "DurationSecsLeft"
	ButtonDisplay = "ButtonDisplay"
	TimeOfUpload = "TimeOfUpload"
	TimeOfRun = "TimeOfRun"
	TimeOfStop = "TimeOfStop"
	TimeOfClear = "TimeOfClear"
	
	attr_accessor :SlotOwner
	attr_accessor :slotProperties

	def updateDurationTimeLeft(slotOwner)
		dl = GetSlotDurationHoursLeft(slotOwner).to_i*60*60 # dl - duration left
		dl += GetSlotDurationMinsLeft(slotOwner).to_i*60
		dl += GetSlotDurationSecsLeft(slotOwner).to_i
		dl -= (getSlotProperties(slotOwner)[TimeOfStop].to_i-getSlotProperties(slotOwner)[TimeOfRun].to_i) # dl is duration left
		
		hours = (dl/3600).to_i
		dl -= hours*3600
		mins = (dl/60).to_i
		dl -= (mins*60).to_i
		getSlotProperties(slotOwner)[DurationHoursLeft] = hours
		getSlotProperties(slotOwner)[DurationMinsLeft] = mins
		getSlotProperties(slotOwner)[DurationSecsLeft] = dl.to_i
	end

	def GetDurationLeft(slotLabelParam)
		# If the button state is Stop, subtract the total time between now and TimeOfRun, then 
		if getSlotProperties(slotLabelParam)[ButtonDisplay] == Stop
			#
			# What does it return?
			#
			dl = GetSlotDurationHoursLeft(slotLabelParam).to_i*60*60 # dl - duration left
			dl += GetSlotDurationMinsLeft(slotLabelParam).to_i*60
			dl += GetSlotDurationSecsLeft(slotLabelParam).to_i
			if getSlotProperties(slotLabelParam)[TimeOfRun].nil?
				"00:00:00"
			else
				dl -= (Time.new.to_i - getSlotProperties(slotLabelParam)[TimeOfRun].to_i)
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
		elsif getSlotProperties(slotLabelParam)[ButtonDisplay] == Run
				return "#{GetSlotDurationHoursLeft(slotLabelParam)}:#{GetSlotDurationMinsLeft(slotLabelParam)}:#{GetSlotDurationSecsLeft(slotLabelParam)}"
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
	
	def getStepCompletion(slotOwner)
		if slotProperties.to_json == "{}"
			getSlotsState()
		end		
		
		if getSlotProperties(slotOwner)[ButtonDisplay] == Load 
			return BlankFileName
		else
			if getSlotProperties(slotOwner)[ButtonDisplay] == Run
				d = Time.now
				d += GetSlotDurationHoursLeft(slotOwner).to_i*60*60
				d += GetSlotDurationMinsLeft(slotOwner).to_i*60
				d += GetSlotDurationSecsLeft(slotOwner).to_i
			else
				puts "getSlotProperties(slotOwner)[TimeOfRun]=#{getSlotProperties(slotOwner)[TimeOfRun]}"
				d = getSlotProperties(slotOwner)[TimeOfRun].to_i
				d += GetSlotDurationHoursLeft(slotOwner).to_i*60*60 # dl - duration left
				d += GetSlotDurationMinsLeft(slotOwner).to_i*60
				d += GetSlotDurationSecsLeft(slotOwner).to_i			
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
	
	def getSlotProperties(slotOwner)
		if slotProperties[slotOwner].nil?
			slotProperties[slotOwner] = Hash.new
		end
		return slotProperties[slotOwner]
	end
	def setConfigFileName(slotOwner, fileNameParam)
		getSlotProperties(slotOwner)[FileName] = fileNameParam
	end
	
	def setDurationHours(slotOwner, durationHoursParam)
		getSlotProperties(slotOwner)[DurationHours] = durationHoursParam
		getSlotProperties(slotOwner)[DurationHoursLeft] = durationHoursParam
	end
	
	def setTimeOfRun(slotOwner)
		getSlotProperties(slotOwner)[TimeOfRun] = Time.now.to_i
	end
	
	def setTimeOfStop(slotOwner)
		getSlotProperties(slotOwner)[TimeOfStop] = Time.now.to_i
	end
	
	def setTimeOfClear(slotOwner)
		getSlotProperties(slotOwner)[TimeOfClear] = Time.now.to_i
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
	
	def setTimeOfUpload(slotOwner)
		getSlotProperties(slotOwner)[TimeOfUpload] = Time.now
	end
	
	def setDurationMinutes(slotOwner, totalMinutesParam)
		getSlotProperties(slotOwner)[DurationMins] = totalMinutesParam
		getSlotProperties(slotOwner)[DurationMinsLeft] = totalMinutesParam		
	end

	def getButtonDisplay(slotOwner)
		if getSlotProperties(slotOwner)[ButtonDisplay].nil?
			getSlotProperties(slotOwner)[ButtonDisplay] = Load
		end
		return getSlotProperties(slotOwner)[ButtonDisplay]
	end
	
	def setToRunMode(slotOwner)
		getSlotProperties(slotOwner)[ButtonDisplay] = Stop
	end
	
	def setToLoadMode(slotOwner)
		setConfigFileName(slotOwner, BlankFileName)
		setDurationHours(slotOwner, "00")
		setDurationMinutes(slotOwner, "00")
		getSlotProperties(slotOwner)[ButtonDisplay] = Load
	end

	def setToAllowedToRunMode(slotOwner)
		getSlotProperties(slotOwner)[ButtonDisplay] = Run
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

	def GetSlotDurationSecsLeft(slotLabelParam)
		if getSlotProperties(slotLabelParam)[DurationSecsLeft].nil?
			getSlotProperties(slotLabelParam)[DurationSecsLeft] = "00"
		end
		return getSlotProperties(slotLabelParam)[DurationSecsLeft]
	end

	def GetSlotDurationMinsLeft(slotLabelParam)
		if getSlotProperties(slotLabelParam)[DurationMinsLeft].nil?
			getSlotProperties(slotLabelParam)[DurationMinsLeft] = "00"
		end
		return getSlotProperties(slotLabelParam)[DurationMinsLeft]
	end
	
	def GetSlotDurationHoursLeft(slotLabelParam)
		if getSlotProperties(slotLabelParam)[DurationHoursLeft].nil?
			getSlotProperties(slotLabelParam)[DurationHoursLeft] = "00"
		end
		return getSlotProperties(slotLabelParam)[DurationHoursLeft]
	end
	
	def GetSlotDurationHours(slotLabelParam)
		if slotProperties[slotLabelParam].nil?
			return "00"
		else
			if slotProperties[slotLabelParam][DurationHours].nil?
				return "00"
			else
				return slotProperties[slotLabelParam][DurationHours]
			end
		end
	end 
	
	def GetSlotDurationMins(slotLabelParam)
		if slotProperties[slotLabelParam].nil?
			return "00"
		else
			if slotProperties[slotLabelParam][DurationMins].nil?
				return "00"
			else
				return slotProperties[slotLabelParam][DurationMins]
			end
		end
	end 
	
	def GetSlotFileName (slotLabelParam)
		if slotProperties[slotLabelParam].nil?
			return BlankFileName
		else
			if slotProperties[slotLabelParam][FileName].nil?
				return BlankFileName
			else
				return slotProperties[slotLabelParam][FileName]
			end
		end
		# End of 'def GetSlotFileName (slotLabelParam)'
	end
	
	def removeWhiteSpace(slotLabelParam)
		return slotLabelParam.delete(' ')
	end
	
	def GetSlotDisplay (slotLabelParam,slotLabel2Param)
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
				 									#{getStepCompletion(slotLabel2Param)}
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
									<font size=\"1.25\" style=\"font-style: italic;\">#{GetSlotFileName(slotLabel2Param)}</font>								
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
										#{GetSlotDurationHours(slotLabel2Param)}:#{GetSlotDurationMins(slotLabel2Param)}
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
											#{GetDurationLeft(slotLabel2Param)}
										</label>
										<input 
											type=\"hidden\"
											name=\"hiddenTimeOfRun_#{slotLabel2Param}\"
											value=\"#{getSlotProperties(slotLabel2Param)[TimeOfRun].to_i}\" />
										<input 
											type=\"hidden\"
											name=\"hiddenDurationLeft_#{slotLabel2Param}\"
											value=\"#{GetSlotDurationHoursLeft(slotLabel2Param)}:#{GetSlotDurationMinsLeft(slotLabel2Param)}:#{GetSlotDurationSecsLeft(slotLabel2Param)}\" />
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
	function updateCountDowns() {
		updateCountDownsSub(\"SLOT1\");
		updateCountDownsSub(\"SLOT2\");
		updateCountDownsSub(\"SLOT3\");
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
		return "
		<html>
			<body>
					<form 
						action=\"/TopBtnPressed?slot=#{@SlotOwner}\" 
						method=\"post\" 
						enctype=\"multipart/form-data\">
						<font size=\"3\">Configuration File Uploader</font>
						<br>
						<input type='file' name='myfile' />
						<br>
						<input type='submit' value='Upload' />
					</form>
			</body>
		</html>
		"
		# end of 'def loadFile'
	end
	
end

set :ui, UserInterface.new
set :port, 1979 # orig 4569

get '/about' do
	'A little about me.'
end

get '/TopBtnPressed' do
	settings.ui.SlotOwner = "#{params[:slot]}"
	if params[:BtnState] == settings.ui.Load
		#
		# The Load button got pressed.
		#
		return settings.ui.loadFile
	elsif params[:BtnState] == settings.ui.Run
		#
		# The Run button got pressed.
		#
		settings.ui.setToRunMode(settings.ui.SlotOwner)
		settings.ui.setTimeOfRun(settings.ui.SlotOwner)
		settings.ui.saveSlotState();
		redirect "../"
	elsif params[:BtnState] == settings.ui.Stop
		#
		# The Stop button got pressed.
		#
		settings.ui.setToAllowedToRunMode(settings.ui.SlotOwner)
		settings.ui.setTimeOfStop(settings.ui.SlotOwner)
		
		#
		# Update the duration time
		# Formula : Time now - Time of run, then convert to hours, mins, sec.
		#
		settings.ui.updateDurationTimeLeft(settings.ui.SlotOwner)
		settings.ui.saveSlotState();
		redirect "../"
	elsif params[:BtnState] == settings.ui.Clear
		#
		# The Clear button got pressed.
		#
		settings.ui.setToLoadMode(settings.ui.SlotOwner)
		settings.ui.setTimeOfClear(settings.ui.SlotOwner)
		settings.ui.saveSlotState();
		redirect "../"
	end
	# return "get in /loadfile - slot = '#{settings.ui.SlotOwner}'"+
end



post '/TopBtnPressed' do
	tbr = "" # To be returned.
	
	#
	# Save the file in the upload folder.
	#
	goodUpload = true
	File.open('uploads/configuration.json' , "w") do |f|
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
		File.open('uploads/configuration.json', "r") do |f|
			f.each_line do |line|
				tbr += line
			end
		end
	
		config = JSON.parse(tbr)
		config["FileName"] = "#{params['myfile'][:filename]}"
		# return "parameter = '#{params}'" # Check the content of config hash object.
	
		#
		# Verify data content
		# 	Duration_TotalHours - must be a number
		# 	Duration_TotalMinutes - must be a number
		#
		settings.ui.setConfigFileName(settings.ui.SlotOwner, config["FileName"])
		settings.ui.setDurationHours(settings.ui.SlotOwner, config["Duration_TotalHours"])
		settings.ui.setDurationMinutes(settings.ui.SlotOwner, config["Duration_TotalMinutes"])
		settings.ui.setTimeOfUpload(settings.ui.SlotOwner)
		settings.ui.setToAllowedToRunMode(settings.ui.SlotOwner)
		settings.ui.saveSlotState()
  end  
  redirect "../"
end

get '/' do 
	return settings.ui.display
end

post '/' do	
	settings.ui.saveSlotState() # Saves the state everytime the display gets refreshed.  10 second resolution...
	return settings.ui.display
end


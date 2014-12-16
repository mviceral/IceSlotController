require 'singleton'
require 'forwardable'
require 'uri'

SetupAtHome = false # So we can do some work at home

class SharedLib
	include Singleton
	#
	# Constants used for sending data to the slot
	#
	PcToBbbCmd = "PcToBbbCmd"
	RunFromPc = "RunFromPc" # Command
	StopFromPc = "StopFromPc" # Command
	ClearErrFromPc = "ClearErrFromPc"
	LoadConfigFromPc = "LoadConfigFromPc" # Command
	ClearConfigFromPc = "ClearConfigFromPc"
	PcToBbbData = "PcToBbbData" # Data flag
	SlotOwner = "SlotOwner"
	ErrorMsg = "ErrorMsg"
	ButtonDisplay = "ButtonDisplay"
	NormalButtonDisplay = "NormalButtonDisplay"
	TotalTimeOfStepsInQueue = "TotalTimeOfStepsInQueue"
	DutSiteActivationMin = "DutSiteActivationMin"

	#
	# Constants used for sending data to PC
	#
	DataLog = "DataLog"
	ConfigurationFileName = "ConfigurationFileName"
	ConfigDateUpload = "ConfigDateUpload"
	AllStepsDone_YesNo = "AllStepsDone_YesNo"
	StepName = "StepName"
	StepNumber = "StepNumber"
	StepTimeLeft = "StepTimeLeft"
	SlotTime = "SlotTime"
	Data = "Data"
	SlotIpAddress = "SlotIpAddress"
	BbbMode = "BbbMode"
	AllStepsCompletedAt = "AllStepsCompletedAt"
	DashLines = "---"
	TotalStepDuration = "TotalStepDuration"
	SLOT1 = "SLOT1"
	SLOT2 = "SLOT2"
	SLOT3 = "SLOT3"
	
	# PathFiles
	PathFile_BbbBackLog = "/mnt/card/PcDown.BackLog"

	# Board State.
	InRunMode = "InRunMode"
	InStopMode = "InStopMode"
	#
	# Constants
	#
	Yes = "Yes"
	No = "No"

	# Shared memory for PC side.
	PC = "Pc"
	
	#  Shared memory for Boad side
	DBaseFileName = "DBaseFileName"
	
	DRbMemoryKey = "DRbMemoryKey"
	# The constants used for referencing mux values, and adc input
	IDUT1 = 0
	IDUT2 = 1
	IDUT3 = 2
	IDUT4 = 3
	IDUT5 = 4
	IDUT6 = 5
	IDUT7 = 6
	IDUT8 = 7
	IDUT9 = 8
	IDUT10 = 9
	IDUT11 = 10
	IDUT12 = 11
	IDUT13 = 12
	IDUT14 = 13
	IDUT15 = 14
	IDUT16 = 15
	IDUT17 = 16
	IDUT18 = 17
	IDUT19 = 18
	IDUT20 = 19
	IDUT21 = 20
	IDUT22 = 21
	IDUT23 = 22
	IDUT24 = 23
	IPS6 = 24
	IPS8 = 25
	IPS9 = 26
	IPS10 = 27
	SPARE = 28
	IP5V = 29
	IP12V = 30
	IP24V = 31
	VPS0 = 32
	VPS1 = 33
	VPS2 = 34
	VPS3 = 35
	VPS4 = 36
	VPS5 = 37
	VPS6 = 38
	VPS7 = 39
	VPS8 = 40
	VPS9 = 41
	VPS10 = 42
	BIBP5V = 43
	BIBN5V = 44
	BIBP12V = 45
	P12V = 46
	P24V = 47
	
	SLOTP5V = 48
	SLOTP3V3 = 49
	SLOTP1V8 = 50
	SlotTemp1 = 51
	CALREF = 52
	SlotTemp2 = 53
	
	IPS0 = 54
	SPS1 = 55
	SPS2 = 56
	SPS3 = 57
	SPS4 = 58
	SPS5 = 59
	SPS6 = 60
	SPS7 = 61						
	
	# Data Type
	AdcInput = "A" # for AdcInput
	MuxData = "M" # for MuxData
	Tcu	= "T" # for TCU
	Gpio = "G" # for general purpose IO values
	Eips = "E" # for Ethernet I (current) ps


	# Config file types
	StepFileConfig = "StepFileConfig"
	PsConfig = "PsConfig"
	TempConfig = "TempConfig"
	MinCurrConfig = "MinCurrConfig"

	# Shared memory accessor
	MemAccessor = "MemAccessor"

	Pc_SlotCtrlIps = "Pc_SlotCtrlIps.config"
    
  #
  # Functions
  #
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
  
	def isInteger(paramStr)  	
  	# returns true is the parameter is an integer
  	if paramStr.length > 0
			ct = 0
			while ct<paramStr.length
				singleChar = paramStr[ct]
				intValue = singleChar.to_i
				if intValue.to_s != singleChar
					return false
				end
				ct += 1
			end
			return true
  	else
  		return false
  	end
  end
  
    def is_a_number?(s)
        s.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
    end

	def getKnownRowNamesFor(fileTypeParam)
		if fileTypeParam == PsConfig				
			configTemplateRows = psConfigFileTemplate.split("\n")
			colToUse = 1
		elsif fileTypeParam  == TempConfig
			configTemplateRows = tempConfigFileTemplate.split("\n")
			colToUse = 0
		end
		knownConfigRowNames = Hash.new
		rowCt = 0
		knownConfigRowNames = Hash.new
		while rowCt<configTemplateRows.length do
			columns = configTemplateRows[rowCt].split(",")
			colName = columns[colToUse].to_s.upcase
			colName = colName.gsub "\t", '' # Removes the trailing tab characters at front of the string if any.
			knownConfigRowNames[colName] = "nn" # nn - not nil.
			rowCt += 1
		end
		return knownConfigRowNames
	end
	
	def minCurrConfigFileTemplate
		return "Pre-Test Config File,,,
		,,,Nom
		Name,Type,Unit,SET
		IDUT,DUT MINIMUM CURRENT [1:24],A,0"
	end

	def tempConfigFileTemplate
		#
		# Temperature config file template.
		#
		return "Temperature,Comment,,Nom,Trip,Trip,FLAG,FLAG,Enable,IDLE,LOAD,START,RUN,STOP,CLEAR
		Name,Type,Unit,SET,MIN,MAX,Tol-,Tol+,control,,,,,,
		TDUT,DUT TEMPERATURE [1:24],C,25,15,135,23.75,26.25,YES,OFF,OFF,ON,ON,OFF,OFF
		TimerRUFP,Delay Ramp Up to full power,seconds,500,,,,,,,,,,,
		TimerRDFP,Delay Ramp Dn to FP,seconds,60,,,,,,,,,,,
		H,Delay UP Max PWM Heat ,Percent,25%,,,,,0-255,,,,,,
		C,Ramp down PWM COOL,Percent,100%,,,,,0-255,,,,,,
		P,Propotional,Value,6,,,,,,,,,,,
		I,Integral,Value,0.6,,,,,,,,,,,
		D,Derivitive,Value,0.15,,,,,,,,,,,"
	end

	def stepConfigFileTemplate
		return "Item,Name,Description,Type,Value
			,Pretest ( site identification),,T,STRING
			1,Power Supplies,PS Config For Pretest.ps_config,File,PS Config For Pretest.ps_config
			2,Mosys TCL Test Vector,Test Vector Name & Path,T,c-shell
			3,DUT Site Activation Min Current File ,SiteMin.minCurr_config,File,SiteMin.minCurr_config
			,Step Number,Step Number in integer,N,1
			1,Power Supplies,PS config file for current step (.ps_config extension file),File,ver2-V0=1.095V V1=1.08V V3=1.115V V7=1.120V and V2=V4=2.1V.ps_config
			2,Temperature,Temperature config file for current step (.temp_config extension file),File,BE2_temp_125cH70.temp_config
			3,Step Name,Step Name,T,This is a step name A
			4,Time,Step Time in minutes,M,585
			5,Temp Wait,Wait time on temperature in minutes.,M,10
			6,Alarm Wait,WAIT TIME ON ALARM,M,1
			7,Log Int,Lot Sample Interval file saving time,M,5
			8,Auto Restart,Auto restart,B,1
			9,Stop on Tolerance,Stop on tolerance limit,B,0
			10,Mosys TCL Test Vector,Test Vector Name & Path,T,c-shell
			11,Next Step,Next Step Name 'B',T,STRING
			,Step Number,Step Number in integer,N,2
			1,Power Supplies,PS config file for current step (.ps_config extension file),File,ver2-V0=V1=V3=V7=1.0_V2=V4=1.5V.ps_config
			2,Temperature,Temperature config file for current step (.temp_config extension file),File,BE2_temp_Room.temp_config
			3,Step Name,Step Name,T,This is a step name B
			4,Time,Step Time in minutes,M,165
			5,Temp Wait,Wait time on temperature in minutes.,M,10
			6,Alarm Wait,WAIT TIME ON ALARM,M,1
			7,Log Int,Lot Sample Interval file saving time,M,5
			8,Auto Restart,Auto restart,B,1
			9,Stop on Tolerance,Stop on tolerance limit,B,0
			10,Mosys TCL Test Vector,Test Vector Name & Path,T,c-shell
			11,Next Step,Next Step Name 'C',T,STRING
			,Step Number,Step Number in integer,N,3
			1,Power Supplies,PS config file for current step (.ps_config extension file),File,ver2-V0=V1=V3=V7=1.0_V2=V4=1.5V.ps_config
			2,Temperature,Temperature config file for current step (.temp_config extension file),File,BE2_temp_103cH70.temp_config
			3,Step Name,Step Name,T,This is a step name C
			4,Time,Step Time in minutes,M,285
			5,Temp Wait,Wait time on temperature in minutes.,M,10
			6,Alarm Wait,WAIT TIME ON ALARM,M,1
			7,Log Int,Lot Sample Interval file saving time,M,5
			8,Auto Restart,Auto restart,B,1
			9,Stop on Tolerance,Stop on tolerance limit,B,0
			10,Mosys TCL Test Vector,Test Vector Name & Path,T,c-shell
			11,Next Step,Next Step Name 'END',T,STRING
			,if Condition,Count >= 10 END,F,FUNCTION
			,Count ++,incrament count,F,FUNCTION"
	end
	
	def psConfigFileTemplate
		return "Config File,,,,,,,,,,Condition,,,,,,
			,,Comment,,Nom,Trip,Trip,FLAG,FLAG,Enable,IDLE,LOAD,START,RUN,STOP,CLEAR,
			index,Name,Type,Unit,SET,MIN,MAX,Tol-,Tol+,control,,,,,,,
			15,VPS0,Slot PS Voltage 0,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			16,IPS0,Slot PS Current 0,A,125,0,140,14,131.25,,,,,,,,
			17,VPS1,Slot PS Voltage 1,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			18,IPS1,Slot PS Current 1,A,125,0,140,14,131.25,,,,,,,,
			19,VPS2,Slot PS Voltage 2  (shared PS2),V,1.5,1.35,1.65,1.425,1.575,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			20,IPS2,Slot PS Current 2 (shared PS2),A,70,0,70,7,73.5,,,,,,,,
			21,VPS3,Slot PS Voltage 3,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			22,IPS3,Slot PS Current 3,A,125,0,140,14,131.25,,,,,,,,
			23,VPS4,Slot PS Voltage 4  (shared PS2),V,1.5,1.35,1.65,1.425,1.575,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			24,IPS4,Slot PS Current 4  (shared PS2),A,70,0,70,7,73.5,,,,,,,,
			25,VPS5,Slot PS Voltage 5,V,ph,ph,ph,ph,ph,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			26,IPS5,Slot PS Current 5,A,ph,ph,ph,ph,ph,,,,,,,,
			27,VPS6,Slot PS Voltage 6,V,3.3,2.97,3.63,3.135,3.465,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
			28,IPS6,Slot PS Current 6,A,3,0,5,0.5,3.15,,,,,,,,
			29,VPS7,Slot PS Voltage 7,V,0.9,0.81,0.99,0.855,0.945,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Ethernet
			30,IPS7,Slot PS Current 7,A,125,0,140,14,131.25,,,,,,,,
			31,VPS8,Slot PS Voltage 8,V,5,4.5,5.5,4.75,5.25,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
			32,IPS8,Slot PS Current 8,A,1,0,3,0.3,1.05,,,,,,,,
			33,VPS9,Slot PS Voltage 9,V,2.1,1.89,2.31,1.995,2.205,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
			34,IPS9,Slot PS Current 9,A,1,0,3,0.3,1.05,,,,,,,,
			35,VPS10,Slot PS Voltage 10,V,2.5,2.25,2.75,2.375,2.625,YES,OFF,OFF,SEQUP,ON,SEQDN,OFF,Slot PCB
			36,IPS10,Slot PS Current 10,A,3,0,5,0.5,3.15,,,,,,,,
			37,IDUT,Dut PS current 24 [1:24],A,23,0,27,2.7,24.15,,,,,,,,
			,,,,,UP,DLYms,DN,DLYms,,,,,,,,
			39,SPS0,Enable-Disable ,SEQ,Ethernent,1,200,9,200,,,,,,,,
			40,SPS1,Enable-Disable ,SEQ,Ethernent,2,200,8,200,,,,,,,,
			41,SPS2,Enable-Disable ,SEQ,Ethernent,3,200,7,200,,,,,,,,
			42,SPS3,Enable-Disable ,SEQ,Ethernent,4,200,6,200,,,,,,,,
			43,SPS4,Enable-Disable ,SEQ,Ethernent,0,0,0,0,,,,,,,,
			44,SPS5,Enable-Disable ,SEQ,Ethernent,0,0,0,0,,,,,,,,
			45,SPS6,Enable-Disable ,SEQ,Slot PCB,5,200,5,200,,,,,,,,
			46,SPS7,Enable-Disable ,SEQ,Ethernent,6,200,4,200,,,,,,,,
			47,SPS8,Enable-Disable ,SEQ,Slot PCB,7,200,3,200,,,,,,,,
			48,SPS9,Enable-Disable ,SEQ,Slot PCB,8,200,2,200,,,,,,,,
			49,SPS10,Enable-Disable ,SEQ,Slot PCB,9,200,1,200,,,,,,,,"
	end
  
  def MakeShellFriendly(str)
		ct = 0
		newStr = ""
		while ct < str.length
			if str[ct] == "\""
				newStr += "\\\""
			else
				newStr += str[ct]
			end
			ct += 1
		end
		return newStr
	end
  
  def getLogFileName(configDateUpload,slotOwnerParam,lotIDParam)
  	configDateUpload = Time.at(configDateUpload.to_i)
		ct = 0
		return "iceLog_brd#{slotOwnerParam}_lot#{lotIDParam}_time#{configDateUpload.strftime("%Y%m%d_%H%M%S")}"
		
	end
  
  def makeUriFriendly(stringParam)  
  	return URI.escape(stringParam)
  end

=begin  
    def makeUriFriendlySub(stringParam,trueFalseParam)
        tbr = replaceStr(stringParam," ","%20",trueFalseParam) # tbr - to be returned
        tbr = replaceStr(tbr,"!","%21",trueFalseParam)
        tbr = replaceStr(tbr,"\"","%22",trueFalseParam)
        tbr = replaceStr(tbr,"#","%23",trueFalseParam)
        tbr = replaceStr(tbr,"$","%24",trueFalseParam)
        tbr = replaceStr(tbr,"%%","%25",trueFalseParam)
        tbr = replaceStr(tbr,"&","%26",trueFalseParam)
        tbr = replaceStr(tbr,"'","%27",trueFalseParam)
        tbr = replaceStr(tbr,"(","%28",trueFalseParam)
        tbr = replaceStr(tbr,")","%29",trueFalseParam)
        tbr = replaceStr(tbr,"*","%2A",trueFalseParam)
        tbr = replaceStr(tbr,"+","%2B",trueFalseParam)
        tbr = replaceStr(tbr,",","%2C",trueFalseParam)
        tbr = replaceStr(tbr,"-","%2D",trueFalseParam)
        tbr = replaceStr(tbr,".","%2E",trueFalseParam)
        tbr = replaceStr(tbr,"/","%2F",trueFalseParam)
        tbr = replaceStr(tbr,":","%3A",trueFalseParam)
        tbr = replaceStr(tbr,";","%3B",trueFalseParam)
        tbr = replaceStr(tbr,"<","%3C",trueFalseParam)
        tbr = replaceStr(tbr,"=","%3D",trueFalseParam)
        tbr = replaceStr(tbr,">","%3E",trueFalseParam)
        tbr = replaceStr(tbr,"?","%3F",trueFalseParam)
        tbr = replaceStr(tbr,"@","%40",trueFalseParam)	
        return tbr
	end
=end

	def replaceStr(stringParam,lookForParam,replaceWithParam,trueFalseParam)
		if trueFalseParam == false
			hold = lookForParam
			lookForParam = replaceWithParam
			replaceWithParam = hold
		end
		
		if stringParam.nil? == false && stringParam.length > 0
			while stringParam.include? lookForParam
				stringParam = stringParam.sub(lookForParam,replaceWithParam)
				# End of 'while stringParam.include? " "'
			end
		end
		return stringParam 
    end
  
    def pause(msgParam,fromParam)
        puts "#{msgParam}"
        puts "      o Paused at #{fromParam}"
        gets
    end

    def getBits(dataParam)
        # puts "dataParam=#{dataParam} dataParam.class=#{dataParam.class} #{__LINE__}-#{__FILE__}"
        bits = dataParam.to_s(2)
        while bits.length < 8
            bits = "0"+bits
        end
        return bits
    end

    def bbbLog(sentMessage)
        if @oldMessage != sentMessage
            @oldMessage = sentMessage
    	    log = "#{Time.new.inspect} : #{sentMessage}"
    	    puts "#{log}"
        end
    end
    
    def ChangeDQuoteToSQuoteForDbFormat(slotInfoJson)
    	# Change all the '"' to '\"' within slotInfoJson
    	ct = 0
    	forDbase = ""
    	while ct < slotInfoJson.length
            if slotInfoJson[ct] == '"'
        	    forDbase += "'"
            else
        	    forDbase += slotInfoJson[ct]
            end
            # puts "forDbase=#{forDbase}"
            # SharedLib.pause "At pause","#{__LINE__}-#{__FILE__}"
    	    ct += 1
    	end
    	return forDbase
    end

    def makeTime2colon2Format(hours,min)
        shours = hours.to_s
        while shours.length<2
            shours = "0"+shours
        end
        
        smin = min.to_s
        if smin.length>2
        	smin = smin[0..1]
        end
        while smin.length<2
            smin = "0"+smin
        end
        return shours+":"+smin
    end

	def setBibID(colContent,slotOwnerParam)
			if colContent[0] == "#{slotOwnerParam} BIB#"
				bibID = colContent[1].chomp
				bibID = bibID.strip
				@bibId[slotOwnerParam] = bibID
			end
	end
	
	def getBibID(slotOwnerParam)
		if @bibId.nil? || @bibId.length == 0
			@bibId = Hash.new
			config = Array.new
			if SetupAtHome
				pathD = "/cygdrive/c/work/slot-controller"
			else
				pathD = `cd ~; pwd`.strip
			end
			File.open("#{pathD}/slot-controller/#{Pc_SlotCtrlIps}", "r") do |f|
				f.each_line do |line|
					config.push(line)
				end			
			end
		
			# Parse each lines and mind the information we need for the report.
			ct = 0
			while ct < config.length 
				colContent = config[ct].split(":")
				setBibID(colContent,"SLOT1")
				setBibID(colContent,"SLOT2")
				setBibID(colContent,"SLOT3")
				ct += 1
			end
		end
		return @bibId[slotOwnerParam]
	end


    class << self
        extend Forwardable
        def_delegators :instance, *SharedLib.instance_methods(false)
    end
    
    def self.make5point2Format(numberParam)
    	numParam = numberParam.to_s
		if numParam.length > 6
			numParam = numParam[0..5]
		end
		while numParam.length < 5
			numParam += "0"
		end
		return numParam
    end
    
    def self.getCurrentDutDisplay(muxData,rawDataParam)
			if muxData.nil? == false && muxData[rawDataParam].nil? == false
				current = make5point2Format((muxData[rawDataParam].to_f/1000.0).round(3))
			else
				current = DashLines
			end
			return current
    	# End of 'getCurrentDutDisplay()'
    end

  # End of 'class Constants'
end    

require 'singleton'
require 'forwardable'

class SharedLib
	include Singleton
	#
	# Constants used for sending data to the slot
	#
	PcToBbbCmd = "PcToBbbCmd"
	RunFromPc = "RunFromPc" # Command
	StopFromPc = "StopFromPc" # Command
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
	TotalStepDuration = "TotalStepDuration"
	# PcListener = "http://192.168.1.210"
	PcListener = "http://192.168.7.1"
	SLOT1 = "SLOT1"
	SLOT2 = "SLOT2"
	SLOT3 = "SLOT3"

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

	# Shared memory accessor
	MemAccessor = "MemAccessor"
    
    #
    # Functions
    #
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

  def uriToStr(stringParam)
  	return makeUriFriendlySub(stringParam,false)
  end
  
  def makeUriFriendly(stringParam)  
  	return makeUriFriendlySub(stringParam,true)
  end
  
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

    def bbbLog(sentMessage)
        if @oldMessage != sentMessage
            @oldMessage = sentMessage
    	    log = "#{Time.new.inspect} : #{sentMessage}"
    	    puts "#{log}"
            `echo "#{log}">>../slot\ activity.log`
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
  
    class << self
        extend Forwardable
        def_delegators :instance, *SharedLib.instance_methods(false)
    end
  # End of 'class Constants'
end
    


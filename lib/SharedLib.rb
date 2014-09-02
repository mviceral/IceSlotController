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

	#
	# Constants used for sending data to PC
	#
    ConfigurationFileName = "ConfigurationFileName"
    ConfigDateUpload = "ConfigDateUpload"
    AllStepsDone_YesNo = "AllStepsDone_YesNo"
    StepName = "StepName"
    StepNumber = "StepNumber"
    StepTotalTime = "StepTotalTime"
    SlotTime = "SlotTime"
    Data = "Data"
    SlotIpAddress = "SlotIpAddress"
    BbbMode = "BbbMode"
    AllStepsCompletedAt = "AllStepsCompletedAt"
    
    #
    # Constants
    #
    Yes = "Yes"
    No = "No"

	# Shared memory for PC side.
		PC = "Pc"
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
    
  
    class << self
        extend Forwardable
        def_delegators :instance, *SharedLib.instance_methods(false)
    end
  # End of 'class Constants'
end
    

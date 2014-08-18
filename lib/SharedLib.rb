require 'singleton'
require 'forwardable'

class SharedLib
	include Singleton
	#
	# Constants
	#
  RunFromPC = "RunFromPC"
  StopFromPC = "StopFromPC"
  LoadConfigFromPC = "LoadConfigFromPC"
  PcToBbbCmd = "PcToBbbCmd"
  PcToBbbData = "PcToBbbData"
  
  #
  # Functions
  #
  def uriToStr(stringParam)
  	puts "uriToStr #{__LINE__}-#{__FILE__} stringParam=#{stringParam}"
  	return makeUriFriendlySub(stringParam,false)
  end
  
  def makeUriFriendly(stringParam)  
  	return makeUriFriendlySub(stringParam,true)
  end
  
  def makeUriFriendlySub(stringParam,trueFalseParam)
  	puts "#{__LINE__}-#{__FILE__} stringParam=#{stringParam}"
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
  	puts "#{__LINE__}-#{__FILE__} tbr=#{tbr}"
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
  
  class << self
    extend Forwardable
    def_delegators :instance, *SharedLib.instance_methods(false)
  end
  # End of 'class Constants'
end
    

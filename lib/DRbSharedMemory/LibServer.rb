require 'drb/drb'
require_relative '../SharedMemory'
# This retains a local reference to all loggers created.  This
# is so an existing logger can be looked up by name, but also
# to prevent loggers from being garbage collected.  A dRuby
# reference to an object is not sufficient to prevent it being
# garbage collected !
class LoggerFactory
	def initialize()
		@data = {}
		@logInfoFromPC = {}
		@shutDownInfoFromPC = {}
	end

	
	def getLogInfoFromPC()
		name = "TheSharedMemObject"
		if @logInfoFromPC[name].nil? == false && @logInfoFromPC[name].size() > 0
			tbr = @logInfoFromPC[name].shift # tbr = to be returned
		else
			tbr = nil
		end
		return tbr
	end
		
	def processLogInfoFromPC(data)
		name = "TheSharedMemObject"
		if !@logInfoFromPC.has_key? name
		    @logInfoFromPC[name] = Array.new
		end
		@logInfoFromPC[name].push(data)
	end
	
	def getShutDownInfoFromPC()
		name = "TheSharedMemObject"
		if @shutDownInfoFromPC[name].nil? == false && @shutDownInfoFromPC[name].size() > 0
			tbr = @shutDownInfoFromPC[name].shift # tbr = to be returned
		else
			tbr = nil
		end	
		return tbr
	end
	
	def processShutDownInfoFromPC(data)
		name = "TheSharedMemObject"
		if !@shutDownInfoFromPC.has_key? name
		    @shutDownInfoFromPC[name] = Array.new
		end
		@shutDownInfoFromPC[name].push(data)
	end
	
	
	def getSharedMem()
		# An existing data can be looked up by name
		# to prevent data from being garbage collected.  A dRuby
		# reference to an object is not sufficient to prevent it being
		# garbage collected!
		name = "TheSharedMemObject"
		if !@data.has_key? name
		    @data[name] = SharedMemory.new
		end
		return @data[name]
	end	
end


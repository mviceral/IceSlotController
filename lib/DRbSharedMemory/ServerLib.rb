require 'drb/drb'
require_relative '../SharedMemory'
# This retains a local reference to all loggers created.  This
# is so an existing logger can be looked up by name, but also
# to prevent loggers from being garbage collected.  A dRuby
# reference to an object is not sufficient to prevent it being
# garbage collected!
class LoggerFactory
	def initialize()
		@data = {}
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


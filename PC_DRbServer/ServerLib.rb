require 'drb/drb'
require_relative '../lib/SharedMemory'
# This retains a local reference to all loggers created.  This
# is so an existing logger can be looked up by name, but also
# to prevent loggers from being garbage collected.  A dRuby
# reference to an object is not sufficient to prevent it being
# garbage collected!
class LoggerFactory
	def initialize()
		@data = SharedMemory.new
	end
	
	def getSharedMem()
		return @data
	end	
end


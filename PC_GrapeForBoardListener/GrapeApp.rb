# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'grape'
require 'singleton'
require 'forwardable'
require 'pp'
# require 'sqlite3'
require_relative '../lib/SharedMemory'

# If you set this true, it will put out some debugging info to STDOUT
# (usually the termninal that you started rackup with)
$debug = true 

module MigrationCount
	# This is the resource we're managing. Not perssistant!
	class Migrations
		include Singleton

		attr_accessor :quantity

		def initialize
			@quantity = 0
		end

		# This bit of magic makes it so you don't have to say
		# Migrations.instance.quantity
		# I.E. Normally to access methods that are using the Singleton
		# Gem, you have to use the itermediate accessor '.instance'
		# This ruby technique makes it so you don't have.
		# Could also be done with method_missing but this is a bit nicer
		# IMHO
		#
		class << self
			extend Forwardable
			def_delegators :instance, *Migrations.instance_methods(false)
		end # end of 'class << self'
	end # End of 'class Migrations'

	# This is the Grape REST API implementation
	class API < Grape::API
		# This makes it so you have to specifiy the API version in the
		# path string
		version 'v1', using: :path

		# Specifies that we're going to accept / send json
		format :json

		# We don't really need Namespaces in a simple example but this
		# shows how. You'll need them soon enough for something real
		# The namespace becomes the resource name and is in the path after
		# the version
		#
		namespace :migrations do
			# POST /vi/migrations/Duts
			# If you supply an integer parameter in the body or the url named 'Id'
			# you will get the record with that id.
			#
			post "/Duts" do
				if params["Duts"]
					#
					# Parse out the data sent from the board					
					#
					receivedData = params['Duts']
					begin
						hash = JSON.parse(receivedData)
						rescue Exception => e
							puts e.message  
							puts e.backtrace.inspect  						
						ensure
					end
					# SharedMemory.
					# puts "1 receivedData = #{receivedData}"
					
        	sharedMem = SharedMemory.new()
        	sharedMem.SetDataBoardToPc(hash)
										
					puts "ConfigurationFileName = #{sharedMem.GetDispConfigurationFileName()}"
					puts "ConfigDateUpload = #{sharedMem.GetDispConfigDateUpload()}"
					puts "AllStepsDone_YesNo = #{sharedMem.GetDispAllStepsDone_YesNo()}"
					puts "BbbMode = #{sharedMem.GetDispBbbMode()}"
					puts "StepName = #{sharedMem.GetDispStepName()}"
					puts "StepNumber = #{sharedMem.GetDispStepNumber()}"
					puts "StepTotalTime = #{sharedMem.GetDispStepTimeLeft()}"
					puts "SlotTime = #{sharedMem.GetDispSlotTime()}"
					puts "SlotIpAddress = #{sharedMem.GetDispSlotIpAddress()}"
					puts "SlotTime = #{sharedMem.GetDispSlotTime()}"
					puts "AdcInput = #{sharedMem.GetDispAdcInput()}"
					puts "MuxData = #{sharedMem.GetDispMuxData()}"
					puts "Tcu = #{sharedMem.GetDispTcu()}"
					puts "AllStepsCompletedAt = #{sharedMem.GetDispAllStepsCompletedAt()}"
					puts "TotalStepDuration = #{sharedMem.GetDispTotalStepDuration()}"
					
					configDateUpload = Time.at(sharedMem.GetDispConfigDateUpload().to_i)
					dBaseFileName = "../steps log records/#{sharedMem.GetDispSlotIpAddress()}_#{configDateUpload.strftime("%Y%m%d_%H%M%S")}_#{sharedMem.GetDispConfigurationFileName()}.db"
					runningOnCentos = true
					if runningOnCentos == false
						if File.file?("#{dBaseFileName}") == false
							# The file does not exists.
							dbRecord = SQLite3::Database.new( "#{dBaseFileName}" )
							if dbRecord.nil?
								SharedLib.bbbLog "db is nil. #{__LINE__}-#{__FILE__}"
							else
									dbRecord.execute("create table log ("+
									"idLogTime int, data TEXT"+     # 'dutNum' the dut number reference of the data
									");")
							end
						else
							# The file already exists.
							dbRecord = SQLite3::Database.open dBaseFileName
						end
	
						forDbase = SharedLib.ChangeDQuoteToSQuoteForDbFormat(receivedData)

						str = "Insert into log(idLogTime, data) "+
						"values(#{sharedMem.GetDispSlotTime()},\"#{forDbase}\")"

						puts "@#{__LINE__}-#{__FILE__} sqlStr = ->#{str}<-"
						begin
							dbRecord.execute "#{str}"
							rescue SQLite3::Exception => e 
							puts "\n\n"
							SharedLib.bbbLog "str = ->#{str}<- #{__LINE__}-#{__FILE__}"
							SharedLib.bbbLog "#{e} #{__LINE__}-#{__FILE__}"
							# End of 'rescue SQLite3::Exception => e'
							ensure

							# End of 'begin' code block that will handle exceptions...
						end
					else
						`echo "#{sharedMem.GetDispSlotTime()},#{receivedData}" >> #{dBaseFileName}`
					end
				end
			end
		end
	end		
end
#  -BBB1410220744|0@1,23.398,22.848,0,20,Ok|1@1,25.575,24.241,0,10,Ok|2@0,25.833,24.687,1,101,Ok|3@0,25.240,23.619,1,101,Ok

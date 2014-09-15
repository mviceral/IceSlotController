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
										
					puts "hash[SharedLib::SlotIpAddress] = #{hash[SharedLib::SlotIpAddress]}, slotConvert = #{sharedMem.convertIpToSlotId(hash[SharedLib::SlotIpAddress])}"
					puts "ConfigurationFileName = #{sharedMem.GetDispConfigurationFileName(hash[SharedLib::SlotIpAddress])}"
					puts "ConfigDateUpload = #{sharedMem.GetDispConfigDateUpload(hash[SharedLib::SlotIpAddress])}"
					puts "AllStepsDone_YesNo = #{sharedMem.GetDispAllStepsDone_YesNo(hash[SharedLib::SlotIpAddress])}"
					puts "BbbMode = #{sharedMem.GetDispBbbMode(hash[SharedLib::SlotIpAddress])}"
					puts "StepName = #{sharedMem.GetDispStepName(hash[SharedLib::SlotIpAddress])}"
					puts "StepNumber = #{sharedMem.GetDispStepNumber(hash[SharedLib::SlotIpAddress])}"
					puts "StepTotalTime = #{sharedMem.GetDispStepTimeLeft(hash[SharedLib::SlotIpAddress])}"
					puts "SlotTime = #{sharedMem.GetDispSlotTime(hash[SharedLib::SlotIpAddress])}"
					puts "SlotIpAddress = #{sharedMem.GetDispSlotIpAddress(hash[SharedLib::SlotIpAddress])}"
					puts "SlotTime = #{sharedMem.GetDispSlotTime(hash[SharedLib::SlotIpAddress])}"
					puts "AdcInput = #{sharedMem.GetDispAdcInput(hash[SharedLib::SlotIpAddress])}"
					puts "MuxData = #{sharedMem.GetDispMuxData(hash[SharedLib::SlotIpAddress])}"
					puts "Tcu = #{sharedMem.GetDispTcu(hash[SharedLib::SlotIpAddress])}"
					puts "AllStepsCompletedAt = #{sharedMem.GetDispAllStepsCompletedAt(hash[SharedLib::SlotIpAddress])}"
					puts "TotalStepDuration = #{sharedMem.GetDispTotalStepDuration(hash[SharedLib::SlotIpAddress])}"
					puts "Eips = #{sharedMem.GetDispEips(hash[SharedLib::SlotIpAddress])}"
					configDateUpload = Time.at(sharedMem.GetDispConfigDateUpload(hash[SharedLib::SlotIpAddress]).to_i)
					dBaseFileName = "../steps log records/#{sharedMem.GetDispSlotIpAddress(hash[SharedLib::SlotIpAddress])}_#{configDateUpload.strftime("%Y%m%d_%H%M%S")}_#{sharedMem.GetDispConfigurationFileName(hash[SharedLib::SlotIpAddress])}.db"
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
						`echo "#{sharedMem.GetDispSlotTime(hash[SharedLib::SlotIpAddress])},#{receivedData}" >> #{dBaseFileName}`
					end
				end
			end
		end
	end		
end
#  -BBB1410220744|0@1,23.398,22.848,0,20,Ok|1@1,25.575,24.241,0,10,Ok|2@0,25.833,24.687,1,101,Ok|3@0,25.240,23.619,1,101,Ok

# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'grape'
require 'singleton'
require 'forwardable'
require 'pp'
require 'drb/drb'
# require 'sqlite3'
require_relative '../lib/SharedMemory'
require_relative '../lib/DRbSharedMemory/ServerLib'

# If you set this true, it will put out some debugging info to STDOUT
# (usually the termninal that you started rackup with)
$debug = true 

SERVER_URI="druby://localhost:8787"

module MigrationCount
	# This is the resource we're managing. Not perssistant!
	class Migrations
		include Singleton

		attr_accessor :quantity

		def initialize
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
		DRb.start_service			
		@@sharedMemService =  DRbObject.new_with_uri(SERVER_URI)
		
		directory = SharedMemory::StepsLogRecordsPath
		asdf = `[ -d #{directory} ] && echo "yes" || echo "no"`
		if asdf.chomp == "no"
			`mkdir #{directory}`
		end

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
					begin
						#
						# Parse out the data sent from the board					
						#
						$SAFE = 0

						receivedData = params['Duts']
						hash = JSON.parse(receivedData)
						
						if hash[SharedLib::DataLog].nil? == false
							# The sent data is a log data.  Write it to file							
							puts "Rec'd data for display. #{__LINE__}-#{__FILE__}"
							configDateUpload = Time.at(hash[SharedLib::ConfigDateUpload].to_i)
							fileName = hash[SharedLib::ConfigurationFileName]
							slotOwnerParam = hash[SharedLib::SlotOwner]
							dBaseFileName = SharedLib.getFileNameRecord(fileName,configDateUpload,slotOwnerParam)+".log"		
							puts "dBaseFileName = #{dBaseFileName} #{__LINE__}-#{__FILE__}"
							puts "hash[SharedLib::DataLog]: #{__LINE__}-#{__FILE__}/n#{hash[SharedLib::DataLog]}"
							`cd #{directory}; echo "#{hash[SharedLib::DataLog]}" >> \"#{dBaseFileName}\"`
						else
							# The sent data is for display
							# puts "hash[SharedLib::SlotOwner]=#{hash[SharedLib::SlotOwner]} #{__LINE__}-#{__FILE__}"
							# puts "hash:#{__LINE__}-#{__FILE__}\n#{hash}"
							sharedMem = @@sharedMemService.getSharedMem()		 
							sharedMem.setDataFromBoardToPc(hash)
						
							# puts "dBaseFileName='#{dBaseFileName}'"
							# logging code.
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
								"values(#{GetDispSlotTime()},\"#{forDbase}\")"

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
=begin
								if sharedMem.logData(hash[SharedLib::SlotOwner]).nil? == false &&
									sharedMem.logData(hash[SharedLib::SlotOwner]).length > 0							
									str = "#{sharedMem.logData(hash[SharedLib::SlotOwner])}"
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
									# puts "dBaseFileName='#{dBaseFileName}', newStr=#{newStr}"
									`cd #{directory}; echo "#{newStr}" >> \"#{dBaseFileName}\"`
								end
=end							
							end
						end
							
						rescue Exception => e
							# The data didn't parse properly.  Do nothing.
							puts e.message  
						ensure
					end
				end
			end
		end
	end		
end
#  -BBB1410220744|0@1,23.398,22.848,0,20,Ok|1@1,25.575,24.241,0,10,Ok|2@0,25.833,24.687,1,101,Ok|3@0,25.240,23.619,1,101,Ok

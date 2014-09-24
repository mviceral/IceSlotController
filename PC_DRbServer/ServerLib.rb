require 'drb/drb'
require_relative '../lib/SharedMemory'
SERVER_URI="druby://localhost:8787"
# This retains a local reference to all loggers created.  This
# is so an existing logger can be looked up by name, but also
# to prevent loggers from being garbage collected.  A dRuby
# reference to an object is not sufficient to prevent it being
# garbage collected!
class LoggerFactory
	SinatraKey = "SinatraKey"
	def initialize()
		@data = {}
	end
	
	def getSharedMem(name)
		if !@data.has_key? name
			@data[name] = SharedMemory.new()
		end			
		return @data[name]
	end

	def setData(hash,name)
		puts "name=#{name}"
		puts "hash=#{hash}"
		begin			
			if !@data.has_key? name
				@data[name] = SharedMemory.new()
			end			

			# puts "hash[SharedLib::SlotOwner].nil? = #{hash[SharedLib::SlotOwner].nil?}"
			if (hash[SharedLib::SlotOwner].nil? == false &&
			       (hash[SharedLib::SlotOwner] != SharedLib::SLOT1 &&
				hash[SharedLib::SlotOwner] != SharedLib::SLOT2 &&
				hash[SharedLib::SlotOwner] != SharedLib::SLOT3) == true) || hash[SharedLib::SlotOwner].nil?
				# Flush out the  memory...
				# @data[name].WriteDataV1("","")
			else
				@data[name].SetDataBoardToPc(hash)
				@data[name].SetDispSlotOwner(hash[SharedLib::SlotOwner])

				puts "\n\n\n"
				puts "Display button = '#{@data[name].GetDispButton(hash[SharedLib::SlotOwner])}'"
				print "TotalTimeOfStepsInQueue ="
puts " '#{@data[name].GetDispTotalTimeOfStepsInQueue(hash[SharedLib::SlotOwner])}'"
				puts "ConfigurationFileName = #{@data[name].GetDispConfigurationFileName(hash[SharedLib::SlotOwner])}"
				puts "ConfigDateUpload = #{@data[name].GetDispConfigDateUpload(hash[SharedLib::SlotOwner])}"
				puts "AllStepsDone_YesNo = #{@data[name].GetDispAllStepsDone_YesNo(hash[SharedLib::SlotOwner])}"
				puts "BbbMode = #{@data[name].GetDispBbbMode(hash[SharedLib::SlotOwner])}"
				puts "StepName = #{@data[name].GetDispStepName(hash[SharedLib::SlotOwner])}"
				puts "StepNumber = #{@data[name].GetDispStepNumber(hash[SharedLib::SlotOwner])}"
				puts "StepTotalTime = #{@data[name].GetDispStepTimeLeft(hash[SharedLib::SlotOwner])}"
				puts "SlotIpAddress = #{@data[name].GetDispSlotIpAddress(hash[SharedLib::SlotOwner])}"
				puts "SlotTime = #{Time.at(@data[name].GetDispSlotTime(hash[SharedLib::SlotOwner]).to_i).inspect}"
				# puts "AdcInput = #{@data[name].GetDispAdcInput(hash[SharedLib::SlotOwner])}"
				puts "MuxData = #{@data[name].GetDispMuxData(hash[SharedLib::SlotOwner])}"
				puts "Tcu = #{@data[name].GetDispTcu(hash[SharedLib::SlotOwner])}"
				puts "AllStepsCompletedAt = #{@data[name].GetDispAllStepsCompletedAt(hash[SharedLib::SlotOwner])}"
				puts "TotalStepDuration = #{@data[name].GetDispTotalStepDuration(hash[SharedLib::SlotOwner])}"
				# puts "Eips = #{@data[name].GetDispEips(hash[SharedLib::SlotOwner])}"
				configDateUpload = Time.at(@data[name].GetDispConfigDateUpload(hash[SharedLib::SlotOwner]).to_i)
				dBaseFileName = "../steps log records/#{hash[SharedLib::SlotOwner]}_#{configDateUpload.strftime("%Y%m%d_%H%M%S")}_#{@data[name].GetDispConfigurationFileName(hash[SharedLib::SlotOwner])}.db"
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
					"values(#{@data[name].GetDispSlotTime()},\"#{forDbase}\")"

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
					if @data[name].GetDispAllStepsDone_YesNo(hash[SharedLib::SlotOwner]) == SharedLib::No && @data[name].GetDispBbbMode(hash[SharedLib::SlotOwner]) == SharedLib::InRunMode
						str = "#{@data[name].GetDispSlotTime(hash[SharedLib::SlotOwner])},#{receivedData}"
						open("#{dBaseFileName}", 'a') { |f|
						  f.puts "#{str}"
						}
					end
				end
			end
		rescue
			# The data didn't parse properly.  Do nothing.
		end
	end

end


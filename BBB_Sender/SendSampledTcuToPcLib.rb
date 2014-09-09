require 'sqlite3'
require 'rest_client'
require 'singleton'
require 'forwardable'
require_relative '../lib/SharedMemory'

class SendSampledTcuToPCLib
    include Singleton
    NO_GOOD_DBASE_FOLDER = "No good database folder"
    MOUNT_CARD_DIR = "/mnt/card"
    TOTAL_DUTS_TO_LOOK_AT = 24
    ITS_MOUNTED = "It's mounted."
    BbbToPc = 'http://192.168.7.1'
    PcToSamePc = "localhost"
    SendToPc = BbbToPc

    def runSampler
        # puts "Running the sampler."
        system('cd ../"BBB_Sampler"; bash runTcuSampler.sh &')
        # puts "Done executing the runTcuSampler.sh script."
        # End of 'def runSampler'
    end
    
    def GetSlotIpAddress()
    	# puts "Within 'def GetSlotIpAddress()'"
	    tbr = `ifconfig eth0 | grep "inet addr" | awk -F: '{print $2}' | awk '{print $1}'` # tbr - to be returned
	    return tbr[0..tbr.length-2]
    end
    
    def RunSender
    	@dirFileRepository = "/mnt/card"
    	if Dir.exists?(@dirFileRepository) == false
    		#
    		# Run a bash command to mount the card.
    		#
    		system("umount /mnt/card") # unmount the card, case it crashes and the user # puts in a new card.
    	end
    
        @pollIntervalInSeconds = 10 
        SharedMemory.Initialize()
        # initialize
        #
        # The goal is - the moment the new data becomes available from the sampler, that's when you start processing
        # like send data to PC for immediate display and for saving it, and saving the data into BBB local storage.
        # This way, there's lots of lee-way for recovery case something happens before the next polling.
        #
        @timeOfData = SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}")
        SendDataToPC("#{__LINE__} #{__FILE__}")
        waitTime = Time.now+@pollIntervalInSeconds
        while SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}") == @timeOfData
            sleep(0.01) 
            # puts("Data is the same!!!")
            # puts "Test RunSender G #{__FILE__}-#{__LINE__}"
            if waitTime < Time.now
                #
                # The Sampler does not seem to be updating the shared memory data.  It must be down.
                # Start the sampler process.
                #
                runSampler
            end
        end
        # puts "Test RunSender H #{__FILE__}-#{__LINE__}"
        
        waitTime = Time.now+@pollIntervalInSeconds
        sentSampledData = @timeOfData
        while true
            # puts "Test RunSender C #{__FILE__}-#{__LINE__}"
            @timeOfData = SharedMemory.GetSlotTime("#{__LINE__}-#{__FILE__}")
            if (sentSampledData != @timeOfData)
                SendDataToPC("#{__LINE__}-#{__FILE__}")
                # puts "Test RunSender E #{__FILE__}-#{__LINE__}"
                sentSampledData = @timeOfData
            else
                #
                # Data is still the same?  Perhaps the sampler died?  Run the sampler.
                #
                # puts "Test RunSender G - SAMPLER DIED!!! #{__FILE__}-#{__LINE__}"
                runSampler
                # puts "Test RunSender H - RESTARTED SAMPLER #{__FILE__}-#{__LINE__}"
            end
            # puts "Test RunSender F #{__FILE__}-#{__LINE__}"
            
            #
            # What if there was a hiccup and waitTime-Time.now becomes negative
            # The code ensures that the process is exactly going to take place at the given interval.  No lag that
            # takes place on processing data.
            #
            if (waitTime-Time.now)<0
                #
                # The code fix for the scenario above.  I can't get it to activate the code below, unless
                # the code was killed...
                #
                puts "#{Time.now.inspect} Warning - time to ship data to PC and save it to local BBB dbase took"
                puts  " longer than poll interval!!!"
                # exit # - the exit code...
                #
                # waitTime = Time.now+pollInterval
            else
            	# puts "Sleeping for #{waitTime.to_f-Time.now.to_f}"
                sleep(waitTime.to_f-Time.now.to_f) 
            end
            waitTime = waitTime+@pollIntervalInSeconds
        end
    end

	def GetDataToSendPc()
        slotInfo = Hash.new()
        slotInfo[SharedLib::ConfigurationFileName] = SharedMemory.GetConfigurationFileName()
        slotInfo[SharedLib::ConfigDateUpload] = SharedMemory.GetConfigDateUpload()
        slotInfo[SharedLib::AllStepsDone_YesNo] = SharedMemory.GetAllStepsDone_YesNo()
        slotInfo[SharedLib::BbbMode] = SharedMemory.GetBbbMode()

        slotInfo[SharedLib::StepName] = SharedMemory.GetStepName()
        slotInfo[SharedLib::StepNumber] = SharedMemory.GetStepNumber()
        slotInfo[SharedLib::StepTimeLeft] = SharedMemory.GetStepTimeLeft()
        slotInfo[SharedLib::SlotTime] = @timeOfData
        slotInfo[SharedLib::AdcInput] = SharedMemory.GetDataAdcInput("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::MuxData] = SharedMemory.GetDataMuxData("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::Tcu] = SharedMemory.GetDataTcu("#{__LINE__}-#{__FILE__}")
        slotInfo[SharedLib::SlotIpAddress] = GetSlotIpAddress()
        slotInfo[SharedLib::AllStepsCompletedAt] = SharedMemory.GetAllStepsCompletedAt()
        slotInfo[SharedLib::TotalStepDuration] = SharedMemory.GetTotalStepDuration();
        slotInfoJson = slotInfo.to_json
		return slotInfoJson
	end
		
    def SendDataToPC(fromParam)
    	# puts "called from #{fromParam}"
    	slotInfoJson = GetDataToSendPc()
    	
    	
    	# Save data into dbase if SharedMemory.GetAllStepsDone_YesNo() == SharedLib::No && 
    	# SharedMemory.GetBbbMode() == SharedLib::InRunMode
        if SharedMemory.GetAllStepsDone_YesNo() == SharedLib::No && SharedMemory.GetBbbMode() == SharedLib::InRunMode
            # The data needs to be logged in...
            if SharedMemory.GetDBaseFileName().nil? == false && SharedMemory.GetDBaseFileName().length > 0
                puts "\n\n\nA Checking #{@dirFileRepository}/#{SharedMemory.GetDBaseFileName()} SharedMemory.GetDBaseFileName().length = #{SharedMemory.GetDBaseFileName().length}  #{__LINE__}-#{__FILE__}"
                # There's a valid dBase file name to save the data.
                puts "B Checking #{@dirFileRepository}/#{@dBaseFileName} #{__LINE__}-#{__FILE__}"
            	if @dBaseFileName != SharedMemory.GetDBaseFileName()
            	    @dBaseFileName = SharedMemory.GetDBaseFileName()
            	    @db = SQLite3::Database.open "#{@dirFileRepository}/#{@dBaseFileName}"
            	end
            	
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
    	        str = "Insert into log(idLogTime, data) "+
        		       "values(#{@timeOfData},\"#{forDbase}\")"
    
                begin
                    @db.execute "#{str}"
                    rescue SQLite3::Exception => e 
                        puts "\n\n"
                		SharedLib.bbbLog "str = ->#{str}<- #{__LINE__}-#{__FILE__}"
                		SharedLib.bbbLog "#{e} #{__LINE__}-#{__FILE__}"
                	    # End of 'rescue SQLite3::Exception => e'
                    ensure
                    
                    # End of 'begin' code block that will handle exceptions...
                end        	
            end
        end
    	

        puts "#{__LINE__}-#{__FILE__} slotInfoJson=#{slotInfoJson}"
        begin
            resp = 
                RestClient.post "#{SendToPc}:9292/v1/migrations/Duts", {Duts:"#{slotInfoJson}" }.to_json, :content_type => :json, :accept => :json
            rescue Exception => e  
                puts e.message  
                puts e.backtrace.inspect
                `echo "#{@timeOfData},#{@dBaseFileName}" >> PcDown.BackLog`
        end
    end

    def nextLogCreation
        # puts "Within 'nextLogCreation' - @logCompletedAt = #{@logCompletedAt.inspect}  #{__FILE__} - #{__LINE__}"
        if @nextLogCreation.nil? && logCompletedAt != nil
            # puts "Within 'nextLogCreation' - @logCompletedAt = #{@logCompletedAt.inspect}  #{__FILE__} - #{__LINE__}"
            @nextLogCreation = logCompletedAt+@createLogInterval_UnitsInHours    # *60*60 converts 
                                                                                    # @createLogInterval_UnitsInHours 
                                                                                    # to seconds
            # End of 'if @nextLogCreation.nil?'
        end 
        return @nextLogCreation
        # End of 'nextLogCreation'
    end

	def printErrorSdCardMissing
		puts "Error.  SD Card Missing."
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
      def_delegators :instance, *SendSampledTcuToPCLib.instance_methods(false)
    end    
    
    # End of 'class SendSampledTcuToPC'
end 

# working on def runThreadForSavingSlotStateEvery10Mins()
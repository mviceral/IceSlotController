# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'grape'
#require 'singleton'
#require 'forwardable'
require 'pp'
require 'sqlite3'
require_relative '../lib/SharedLib'
require_relative '../lib/SharedMemory'
require_relative '../BBB_Sender/SendSampledTcuToPcLib'

# If you set this true, it will put out some debugging info to STDOUT
# (usually the termninal that you started rackup with)
$debug = true 

module PcListenerModule
	# This is the resource we're managing. Not perssistant!
	class PcListener
		# include Singleton
		

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
		# class << self
		#	extend Forwardable
		#	def_delegators :instance, *PcListener.instance_methods(false)
		# end # end of 'class << self'
	end # End of 'class PcListener'

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
    namespace :pclistener do
        # GET /vi/pclistener
        get "/" do
          	{registers:@@bbbSetter.gPIO2.forTesting_getGpio2State()}
        end		
    end
    
		namespace :pclistener do
			# POST /vi/pclistener
			# If you supply an integer parameter in the body or the url named 'Id'
			# you will get the record with that id.
			#
			post "/" do
				if params["#{SharedLib::PcToBbbCmd}"].nil? == false
					#
					# Parse out the data sent from BBB
					#
					mode = params["#{SharedLib::PcToBbbCmd}"]
					puts "\n\n\n"
					
					#
					#	Tell sampler to Run if mode = run, Stop if mode = stop, etc.
					#
					puts "PC sent '#{mode}'"
					sharedMem = SharedMemory.new()
					hash = JSON.parse(params["#{SharedLib::PcToBbbData}"])
					sharedMem.SetSlotOwner(hash["SlotOwner"])
					case mode
					when SharedLib::ClearConfigFromPc
						sharedMem.ClearConfiguration("#{__LINE__}-#{__FILE__}")
						# return {bbbResponding:"#{SendSampledTcuToPCLib.GetDataToSendPc(sharedMem)}"}						
					when SharedLib::RunFromPc
					when SharedLib::StopFromPc
					when SharedLib::LoadConfigFromPc
						puts "LoadConfigFromPc code block got called. #{__LINE__}-#{__FILE__}"
						# puts "hash=#{hash}"
						puts "SlotOwner=#{hash["SlotOwner"]}"
						date = Time.at(hash[SharedLib::ConfigDateUpload])
						#puts "PC time - '#{date.strftime("%d %b %Y %H:%M:%S")}'"
						# Sync the board time with the pc time
						`echo "date before setting:";date`
						`date -s "#{date.strftime("%d %b %Y %H:%M:%S")}"`
						`echo "date after setting:";date`
						sharedMem.SetConfiguration(hash,"#{__LINE__}-#{__FILE__}")
						# return {bbbResponding:"#{SendSampledTcuToPCLib.GetDataToSendPc(sharedMem)}"}						
					else
						`echo "#{Time.new.inspect} : mode='#{mode}' not recognized. #{__LINE__}-#{__FILE__}">>/tmp/bbbError.log`
					end
					sharedMem.SetPcCmd(mode,"#{__LINE__}-#{__FILE__}")
				end
				{bbbResponding:"#{mode}"}
			end
		end
	end		
end
""

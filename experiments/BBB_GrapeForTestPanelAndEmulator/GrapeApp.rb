# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'grape'
#require 'singleton'
#require 'forwardable'
require 'pp'
require 'sqlite3'
require_relative "../BBB_Shared Memory for GPIO2 Ruby/SharedMemoryGPIO2"
require_relative "../BBB_GPIO2 Interface Ruby/GPIO2"
require 'json'

# If you set this true, it will put out some debugging info to STDOUT
# (usually the termninal that you started rackup with)
$debug = true 

@@initialized = false

module BbbSetterModule
	# This is the resource we're managing. Not perssistant!
	class BbbSetter
		# include Singleton
		

		def initialize
		    puts "BbbSetter initialize got called."
          	@sharedGpio2 = SharedMemoryGpio2.new
          	@gpio2 = GPIO2.new
          	fromSharedMem = @sharedGpio2.GetData()
		    puts "A fromSharedMem=#{fromSharedMem}."
          	if fromSharedMem[0.."BbbShared".length-1] != "BbbShared"
                #
                # The Shared memory is not initialized.  Set it up.
                #
                puts "A.1 Initializing shared mem in BBB."
                parsed = Hash.new
                @sharedGpio2.WriteData("BbbShared"+parsed.to_json)
          	end
          	fromSharedMem = @sharedGpio2.GetData()
		    puts "B fromSharedMem=#{fromSharedMem}."
		end
		
		def gPIO2
		    return @gpio2
		end
		
		def GetData
		    puts "GetData got called."
		    return @sharedGpio2.GetData()
		end

		def WriteData(dataParam)
		    puts "WriteData got called."
		    return @sharedGpio2.WriteData(dataParam,__LINE__,__FILE__)
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
		#	def_delegators :instance, *BbbSetter.instance_methods(false)
		# end # end of 'class << self'
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
        namespace :bbbsetter do
            # GET /vi/bbbsetter
            get "/" do
                if @@initialized == false
                    @@initialized == true
                    puts "within GET / and initializing stuff."
                    @@bbbSetter = BbbSetter.new
                    if @@bbbSetter.nil?
                        puts "@@bbbSetter is nil after initialization..."
                    end
                end
                
              	fromSharedMem = @@bbbSetter.GetData()
              	puts "Within GET / - fromSharedMem=#{fromSharedMem}"
              	if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
              		# The shared memory has some legit data in it.
              		parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
              	else
              	    parsed = Hash.new
              	end
              	{registers:parsed}
            end		
        end
    
		namespace :bbbsetter do
			# POST /vi/migrations/Duts
			# If you supply an integer parameter in the body or the url named 'Id'
			# you will get the record with that id.
			#
			post "/" do
				if params["addr"].nil? == false && params["data"].nil? == false
					#
					# Parse out the data sent from BBB
					#
					addr = params["addr"]
					data = params["data"]
					puts "receivedData - addr = #{addr}, addr.class=#{addr.class}, data = #{data}, data.class=#{data.class}" 
					puts "A calling @@bbbSetter.gPIO2.setGPIO2(addr.to_i, data.to_i) #{__LINE__}-#{__FILE__}" 
                  	fromSharedMem = @@bbbSetter.GetData()
                  	if fromSharedMem[0.."BbbShared".length-1] == "BbbShared"
                  		# The shared memory has some legit data in it.
                  		parsed = JSON.parse(fromSharedMem["BbbShared".length..-1])
                  	else
                  	    parsed = Hash.new
                  	end
                  	parsed[addr] = data
              	    @@bbbSetter.WriteData("BbbShared"+parsed.to_json)
					@@bbbSetter.gPIO2.setGPIO2(addr.to_i, data.to_i)
					puts "B calling @@bbbSetter.gPIO2.setGPIO2(addr.to_i, data.to_i) #{__LINE__}-#{__FILE__}" 
					#
					# Make an image of the received data into the shared memory case we have to reboot this grape app
					# and just get the latest saved data from the shared.
					#
					parsed
				end
			end
		end
	end		
end

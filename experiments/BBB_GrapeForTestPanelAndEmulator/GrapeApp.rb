# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require 'grape'
#require 'singleton'
#require 'forwardable'
require 'pp'
require 'sqlite3'
require_relative "../BBB_GPIO2 Interface Ruby/GPIO2"

# If you set this true, it will put out some debugging info to STDOUT
# (usually the termninal that you started rackup with)
$debug = true 

@@initialized = false

module BbbSetterModule
	# This is the resource we're managing. Not perssistant!
	class BbbSetter
		# include Singleton
		

		def initialize
          	@gpio2 = GPIO2.new
		end
		
		def gPIO2
		    return @gpio2
		end
=begin		
		def GetData
		    puts "GetData got called."
		    return @sharedGpio2.GetData()
		end

		def WriteData(dataParam)
		    puts "WriteData got called."
		    return @sharedGpio2.WriteData(dataParam)
		end
=end
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
                    @@bbbSetter = BbbSetter.new
                    @@bbbSetter.gPIO2.getForInitGetImagesOf16Addrs()
                    if @@bbbSetter.nil?
                        puts "@@bbbSetter is nil after initialization..."
                    end
                end
                

              	{registers:@@bbbSetter.gPIO2.forTesting_getGpio2State()}
            end		
        end
    
		namespace :bbbsetter do
			# POST /vi/migrations/Duts
			# If you supply an integer parameter in the body or the url named 'Id'
			# you will get the record with that id.
			#
			post "/" do
                if @@initialized == false
                    @@initialized == true
                    @@bbbSetter = BbbSetter.new
                    @@bbbSetter.gPIO2.getForInitGetImagesOf16Addrs()
                    if @@bbbSetter.nil?
                        puts "@@bbbSetter is nil after initialization..."
                    end
                end
                
				if params["addr"].nil? == false && params["data"].nil? == false
					#
					# Parse out the data sent from BBB
					#
					addr = params["addr"]
					data = params["data"]
					@@bbbSetter.gPIO2.setGPIO2(addr.to_i, data.to_i)
					#
					# Make an image of the received data into the shared memory case we have to reboot this grape app
					# and just get the latest saved data from the shared.
					#
					@@bbbSetter.gPIO2.forTesting_getGpio2State()
				end
			end
		end
	end		
end

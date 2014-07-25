require 'grape'
require 'singleton'
require 'forwardable'
require 'pp'
require 'sqlite3'

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
					# Parse out the data sent from BBB
					#
					receivedData = params['Duts']
					# puts "1 receivedData = #{receivedData}" 
					receivedData = receivedData.partition("BBB")[2]
					# puts "2 receivedData = #{receivedData}" 
					timeOfData = receivedData.partition("|")
					dutData = timeOfData[2]

					#
					# Get the count so we have a proper ID
					#
					latestDb = SQLite3::Database.open "latest.db"
					latestDb.results_as_hash = true

					str = "update Latest set slotData = \"#{dutData}\", slotTime=#{timeOfData[0]} where idData = 1"
					# puts "str=#{str}"
					latestDb.execute "#{str}"


					#
					# Save the data to the dbase record.
					#
					dbRecord = SQLite3::Database.open "dbRecord.db"
					# dbRecord.resutls_as_hash = true
					str = "insert into dbRecord (slotTime, slotData) values(#{timeOfData[0]},\"#{dutData}\")"
					# puts "str=#{str}"
					dbRecord.execute "#{str}"					
					{dataTime:timeOfData[0]}
				end
			end
		end
	end		
end

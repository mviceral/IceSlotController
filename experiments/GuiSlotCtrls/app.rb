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
			
			# GET /vi/migrations/cars
			get "/cars" do
				puts "Migrations.quantity: #{Migrations.quantity.inspect}" if $debug


				db = SQLite3::Database.open "latest.db"
				db.results_as_hash = true

				ary = db.execute "SELECT * FROM Cars"    
				asdf = []
				ary.each do |row|
					fetchedData = {
					:Id => row['Id'],
					:Name => row['Name'], 
					:Price => row['Price']
					}
					asdf.push(fetchedData)
				end

				#rescue SQLite3::Exception => e 
				#    puts "Exception occured"
				#    puts e

				#ensure
				#    db.close if db
				#
				asdf 
			end

			# POST /vi/migrations/Duts
			# If you supply an integer parameter in the body or the url named 'Id'
			# you will get the record with that id.
			#
			post "/Duts" do
				if params["Duts"]
					#
					# Get the count so we have a proper ID
					#
					db = SQLite3::Database.open "latest.db"
					db.results_as_hash = true

					#
					# Parse out the data sent from BBB
					#
					receivedData = params['Duts']
					timeOfData = receivedData.partition("|")
					dutData = timeOfData[2]
					str = "update Latest set slotData = \"#{dutData}\", slotTime=#{timeOfData[0]} where idData = 1"
					# puts "str=#{str}"
					db.execute "#{str}"
				end
			end


			get "/:name" do
				# matches "GET /hello/foo" and "GET /hello/bar"
				# params[:name] is 'foo' or 'bar'
				str = "<table><row></row></table>Hello #{params[:name]}!"
				formatter str: HtmlFormatter 
			end
			
			# POST /vi/migrations/inc
			# If you supply an integer parameter in the body or the url named 'value'
			# it will add that ingeter to the current count
			# If you don't supply a parameter it increments the count by 1
			#
			post "/submit" do
				html = 'You entered "'+params['data']+'"'
				return html
			end
		end
	end		
end
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
    end
  end
  
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
      # GET /vi/migrations
      get "/" do
        puts "Migrations.quantity: #{Migrations.quantity.inspect}" if $debug


	db = SQLite3::Database.open "test.db"
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
        { cars: asdf }
      end


	# POST /vi/migrations/car
	# If you supply an integer parameter in the body or the url named 'Id'
	# you will get the record with that id.
	#
      	post "/car" do
		puts "POST /car: params['Id']: #{params[:Id].inspect}" if $debug
		puts "POST /car: params['Car']: #{params["Car"].inspect}  params['Price']:#{params["Price"].inspect}" if $debug
		if params["Id"]
			asdf = []
			db = SQLite3::Database.open "test.db"
			db.results_as_hash = true
			ary = db.execute "SELECT * FROM Cars where Id= #{params["Id"]}"    
			ary.each do |row|
				fetchedData = {
					:Id => row['Id'],
					:Name => row['Name'], 
					:Price => row['Price']
				}
				asdf.push(fetchedData)
			end
			{ count: asdf }
		elsif params["Car"] && params["Price"]
			#
			# Get the count so we have a proper ID
			#
			db = SQLite3::Database.open "test.db"
			db.results_as_hash = true
			ary = db.execute "select count(*) as total from Cars"
			total = 0
			ary.each do |row|
				total += row['total']
			end 
			total += 1
			str = "Insert into Cars(id,name,price) values(#{total},\"#{params["Car"]}\",#{params["Price"]})"
			puts "POST /car: params['Car']: #{params["Car"]}" if $debug
			puts "total=->#{total}<-, str=->#{str}<-" if $debug
			db.execute "#{str}"

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
			{ car: asdf }
		end
      	end


      # POST /vi/migrations/inc
      # If you supply an integer parameter in the body or the url named 'value'
      # it will add that ingeter to the current count
      # If you don't supply a parameter it increments the count by 1
      #
      post "/inc" do
        puts "POST /inc: params['value']: #{params[:value].inspect}" if $debug
        if params["value"]
          Migrations.quantity += params["value"].to_i
        else
          Migrations.quantity += 1
        end
      end
    end
  end
end

require 'rest_client'
require 'singleton'
require 'forwardable'

# module SendThermalSiteSampleToLinuxBox
    # End of 'module MigrationCount'
# end
    class GetDataFromDb
        include Singleton

        def SendSampleDataToLinuxBox
            # db = SQLite3::Database.open "NotSentData.db"
        	# db.results_as_hash = true
        	# ary = db.execute "select * from NotSentData"
        	puts "SendSampleDataToLinuxBox got called."
            # response = RestClient.get 'http://192.168.7.1:9292/v1/migrations/'
            response = RestClient.post "http://192.168.7.1:9292/v1/migrations/Duts", {Duts:"#{allDutData}" }.to_json, :content_type => :json, :accept => :json
            puts "response.code=#{response.code}"
            puts "response.cookies=#{response.cookies}"
            puts "response.headers=#{response.headers}"
            puts "response.to_str=#{response.to_str}"
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
          def_delegators :instance, *GetDataFromDb.instance_methods(false)
        end    
        
        # End of 'class GetDataFromDb'
    end 

GetDataFromDb.SendSampleDataToLinuxBox
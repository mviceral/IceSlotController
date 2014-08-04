#\ -p 8000

#
# The code above '#\ -p 8000' sets the Grape port to run on 8000
#
require './GrapeApp.rb'
use Rack::Reloader
run BbbSetterModule::API

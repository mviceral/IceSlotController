#\ -p 8000

#
# The code above '#\ -p 8000' sets the Grape port to run on 8000
#
require './GrapeAppForPcListener.rb'
use Rack::Reloader
run PcListenerModule::API

require './GrapeApp.rb'
use Rack::Reloader
run MigrationCount::API

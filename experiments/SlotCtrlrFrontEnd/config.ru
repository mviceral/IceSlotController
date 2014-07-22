require './app.rb'
use Rack::Reloader
run MigrationCount::API

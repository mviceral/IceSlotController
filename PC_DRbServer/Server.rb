require 'drb/drb'
require_relative '../lib/SharedMemory'
URI="druby://localhost:8787"
FRONT_OBJECT=SharedMemory.new()
$SAFE = 1 # disable eval() and friends
DRb.start_service(URI, FRONT_OBJECT)
DRb.thread.join

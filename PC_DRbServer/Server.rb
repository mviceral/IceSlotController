require 'drb/drb'
require_relative '../lib/SharedMemory'
require_relative 'ServerLib'
FRONT_OBJECT = LoggerFactory.new()
$SAFE = 1   # disable eval() and friends
DRb.start_service(SERVER_URI, FRONT_OBJECT)
DRb.thread.join

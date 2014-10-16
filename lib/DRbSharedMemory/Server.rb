require 'drb/drb'
require_relative 'LibServer'
URI="druby://localhost:8787"
FRONT_OBJECT=LoggerFactory.new()
# $SAFE = 1 # disable eval() and friends
$SAFE = 0 # disable eval() and friends
DRb.start_service(URI, FRONT_OBJECT)
DRb.thread.join

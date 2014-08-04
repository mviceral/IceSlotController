#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'GPIO2'

gpio2 = GPIO2.new
gpio2.testWithScope
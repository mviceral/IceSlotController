#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'Port2Interface.so'
require 'beaglebone'
include Beaglebone

include Port2Interface

GPIOPin.new(:P8_45, :IN) 
GPIOPin.new(:P8_46, :IN) 
GPIOPin.new(:P8_43, :IN) 
GPIOPin.new(:P8_44, :IN) 
GPIOPin.new(:P8_41, :IN) 
GPIOPin.new(:P8_42, :IN) 
GPIOPin.new(:P8_39, :IN) 
GPIOPin.new(:P8_40, :IN) 
initPort2()

addr = 0
data = 0
while true
    if addr<15
        addr = addr+1
    else
        addr = 0
    end

    if data<255
        data = data+1
    else
        data = 0
    end
    sendToPort2(addr,data)
    a = getFromPort2(addr)
    # puts "a=#{a}"
end


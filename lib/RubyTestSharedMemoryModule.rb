#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemory'


#WriteDataToSharedMemory("abcd12345")
sm = SharedMemory.new
fromSharedMem = sm.GetDataV1()
puts "Content of fromSharedMem=#{fromSharedMem}"
# newData = "abcd12345"
sm.WriteDataV1("This is a ruby test memory sharing.","")
fromSharedMem = sm.GetDataV1()
puts "NEW Content of fromSharedMem=#{fromSharedMem}"

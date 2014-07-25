#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemory'


#WriteDataToSharedMemory("abcd12345")
SharedMemory.Initialize()
fromSharedMem = SharedMemory.GetData()
puts "Content of fromSharedMem=#{fromSharedMem}"
# newData = "abcd12345"
SharedMemory.WriteData("This is a ruby test memory sharing.")
fromSharedMem = SharedMemory.GetData()
puts "NEW Content of fromSharedMem=#{fromSharedMem}"

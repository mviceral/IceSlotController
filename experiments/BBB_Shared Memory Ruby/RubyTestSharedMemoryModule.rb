#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
require_relative 'SharedMemoryModule.so'

include SharedMemoryModule

#WriteDataToSharedMemory("abcd12345")
InitializeSharedMemory()
fromSharedMem = GetDataFromSharedMemory()
puts "Content of fromSharedMem=#{fromSharedMem}"
newData = "abcd12345"
WriteDataToSharedMemory(newData)
fromSharedMem = GetDataFromSharedMemory()
puts "NEW Content of fromSharedMem=#{fromSharedMem}"

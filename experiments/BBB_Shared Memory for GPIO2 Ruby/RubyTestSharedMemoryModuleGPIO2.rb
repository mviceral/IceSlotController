#
# To run:
# clear; ruby extconf.rb ; make; ruby RubyTestSharedMemoryModuleGPIO2.rb
#
require_relative 'SharedMemoryGPIO2'


#WriteDataToSharedMemory("abcd12345")
SharedMemoryGpio2.Initialize()
fromSharedMem = SharedMemoryGpio2.GetData()
puts "Content of fromSharedMem=#{fromSharedMem}"
# newData = "abcd12345"
# SharedMemoryGpio2.WriteData("This is a ruby test memory sharing.")
# fromSharedMem = SharedMemoryGpio2.GetData()
# puts "NEW Content of fromSharedMem=#{fromSharedMem}"

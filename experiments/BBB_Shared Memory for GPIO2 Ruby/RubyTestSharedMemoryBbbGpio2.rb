#
# To run:
# clear; ruby extconf.rb ; make; ruby RubyTestSharedMemoryModuleGPIO2.rb
#
require_relative 'SharedMemoryBbbGpio2'


#WriteDataToSharedMemory("abcd12345")
smgpio2 = SharedMemoryBbbGpio2.new
fromSharedMem = smgpio2.GetData()
puts "Content of fromSharedMem=#{fromSharedMem}"
# newData = "abcd12345"
smgpio2.WriteData("This is a ruby test memory sharing.")
fromSharedMem = smgpio2.GetData()
puts "NEW Content of fromSharedMem=#{fromSharedMem}"

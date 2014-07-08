require 'beaglebone'
include Beaglebone

#puts "Values before setting the pins"
#puts "P9_11: "+ `cat $PINS | grep 870`
#puts "P9_12: "+ `cat $PINS | grep 878`
#puts "P9_13: "+ `cat $PINS | grep 874`
#puts "P9_14: "+ `cat $PINS | grep 848`
#puts "P9_15: "+ `cat $PINS | grep 840`
#puts "P9_16: "+ `cat $PINS | grep 84c`
#puts "P9_17: "+ `cat $PINS | grep 95c`
#puts "P9_18: "+ `cat $PINS | grep 958`
#puts "P9_21: "+ `cat $PINS | grep 954`
#puts "P9_23: "+ `cat $PINS | grep 844`
#puts "P9_41: "+ `cat $PINS | grep 9b4`


#GPIO.pin_mode(:P9_1, :IN) #GND
#GPIO.pin_mode(:P9_3, :IN) #DC_3.3V
#GPIO.pin_mode(:P9_5, :IN) #VDD_5v
#GPIO.pin_mode(:P9_7, :IN) #SYS_5v
#GPIO.pin_mode(:P9_9, :IN) #PWR_BUT
#GPIO.pin_mode(:P9_11, :IN)
#GPIO.pin_mode(:P9_13, :IN)
#GPIO.pin_mode(:P9_15, :IN)
#GPIO.pin_mode(:P9_17, :IN)
#GPIO.pin_mode(:P9_19, :IN) #Allocated
#GPIO.pin_mode(:P9_21, :IN)
#GPIO.pin_mode(:P9_23, :IN)
#GPIO.pin_mode(:P9_25, :IN) #Allocated
#GPIO.pin_mode(:P9_29, :IN) #Allocated
#GPIO.pin_mode(:P9_31, :IN) #Allocated
#GPIO.pin_mode(:P9_33, :IN) #AIN4
#GPIO.pin_mode(:P9_35, :IN) #AIN6
#GPIO.pin_mode(:P9_37, :IN) #AIN2
#GPIO.pin_mode(:P9_39, :IN) #AIN0
#GPIO.pin_mode(:P9_41, :IN)
#GPIO.pin_mode(:P9_43, :IN) #GND
#GPIO.pin_mode(:P9_45, :IN) #GND


#GPIO.pin_mode(:P9_2, :OUT) #GND
#GPIO.pin_mode(:P9_4, :OUT) #DC_3.3V
#GPIO.pin_mode(:P9_6, :OUT) #VDD_5v
#GPIO.pin_mode(:P9_8, :OUT) #SYS_5V
#GPIO.pin_mode(:P9_10, :OUT) #SYS_RESETn
#GPIO.pin_mode(:P9_12, :OUT)
#GPIO.pin_mode(:P9_14, :OUT)
#GPIO.pin_mode(:P9_16, :OUT)
#GPIO.pin_mode(:P9_18, :OUT)
#GPIO.pin_mode(:P9_20, :OUT) #Allocated
#GPIO.pin_mode(:P9_22, :OUT)
#GPIO.pin_mode(:P9_24, :OUT)
#p9_26 = GPIOPin.new(:P9_26, :IN)
#a = 1
#while a == 1 do
#	puts "state = #{p9_26.digital_read}"
#end
#GPIO.pin_mode(:P9_28, :OUT) #Allocated
#GPIO.pin_mode(:P9_30, :OUT)
#GPIO.pin_mode(:P9_32, :OUT) #VACD
#GPIO.pin_mode(:P9_34, :OUT) #AGND
#GPIO.pin_mode(:P9_36, :OUT) #AIN5
#GPIO.pin_mode(:P9_38, :OUT) #AIN3
#GPIO.pin_mode(:P9_40, :OUT) #AIN1
#GPIO.pin_mode(:P9_42, :OUT)
#GPIO.pin_mode(:P9_44, :OUT) #GND

#puts ":P9_12 enabled = #{GPIO.enabled?(:P9_12)}"
#puts ":P9_24 enabled = #{GPIO.enabled?(:P9_24)}"
#puts ":P8_11 enabled = #{GPIO.enabled?(:P8_11)}"
#puts ":P8_12 enabled = #{GPIO.enabled?(:P8_12)}"
#puts ":P8_13 enabled = #{GPIO.enabled?(:P8_13)}"

#puts ":P9_12 mode = #{GPIO.get_gpio_mode(:P9_12)}"
#puts ":P9_24 mode = #{GPIO.get_gpio_mode(:P9_24)}"
#puts ":P8_11 mode = #{GPIO.get_gpio_mode(:P8_11)}"
#puts ":P8_12 mode = #{GPIO.get_gpio_mode(:P8_12)}"
#puts ":P8_13 mode = #{GPIO.get_gpio_mode(:P8_13)}"

#GPIO.get_gpio_state(:P9_12)
#GPIO.get_gpio_state(:P9_24)
#GPIO.get_gpio_state(:P8_11)
#GPIO.get_gpio_state(:P8_12)
#GPIO.get_gpio_state(:P8_13)

## Create an led object for each LED
#led1 = GPIOPin.new(:USR0, :OUT)
#led2 = GPIOPin.new(:USR1, :OUT)
#led3 = GPIOPin.new(:USR2, :OUT)
#led4 = GPIOPin.new(:USR3, :OUT)

## Run the following block 5 times
#5.times do
#  # Iterate over each LED
#  [led1,led2,led3,led4].each do |led|
#    # Turn on the LED
#    led.digital_write(:HIGH)
#    # Delay 0.25 seconds
#    sleep 0.25
#    # Turn off the LED
#    led.digital_write(:LOW)
#  end
#end


#puts "Values After setting the pins"
#puts "P9_11: "+ `cat $PINS | grep 870`
#puts "P9_12: "+ `cat $PINS | grep 878`
#puts "P9_13: "+ `cat $PINS | grep 874`
#puts "P9_14: "+ `cat $PINS | grep 848`
#puts "P9_15: "+ `cat $PINS | grep 840`
#puts "P9_16: "+ `cat $PINS | grep 84c`
#puts "P9_17: "+ `cat $PINS | grep 95c`
#puts "P9_18: "+ `cat $PINS | grep 958`
#puts "P9_21: "+ `cat $PINS | grep 954`
#puts "P9_23: "+ `cat $PINS | grep 844`
#puts "P9_41: "+ `cat $PINS | grep 9b4`


# Run block on every character read from UART1
# uart1 = UARTDevice.new(:UART1, 9600)
#a = 1
#while a==1
#	str = uart1.readchar
#	puts str
#end

# Run the AIN P9_33
#a = 1
#while a==1 do
# puts "ain = #{AIN.read(:P9_33)}"
#end

i = 0
num = 5
time0 = Time.now
timeStop = time0+6 # 5 seconds later?
while Time.now < timeStop  do
   AIN.read(:P9_33)
   i +=1
end
time1 = Time.now

puts "Time diff: #{time1.to_f-time0.to_f} total count: #{i}"

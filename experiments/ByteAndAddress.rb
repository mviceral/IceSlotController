=begin
BeagleBone Black HDMI Cape must be disabled.  Follow the article below.

http://www.logicsupply.com/blog/2013/07/18/disabling-the-beaglebone-black-hdmi-cape/
Disabling the BeagleBone Black HDMI Cape
The HDMI port on the BeagleBone Black is implemented as a virtual cape. This virtual cape uses pins on the 
expansion headers, limiting the available pins. If you don’t need HDMI you gain 20 more GPIO pins by disabling  
the HDMI cape. Other reasons for disabling HDMI are to make UART 5 and the flow control for UART 3 and 4 available 
or to get more PWM pins. Follow the instructions below to disable the HDMI cape and make pins 27 to 46 on header 
P8 available.

Before you start, it’s always a good idea to update your BeagleBone Black with the latest Angstrom image.
Use SSH to connect to the BeagleBone Black. You can use the web based GateOne SSH client or use PuTTY and connect 
to beaglebone.local or 192.168.7.2

user name: root 
password: <enter>

Mount the FAT partition:
mount /dev/mmcblk0p1  /mnt/card

Edit the uEnv.txt on the mounted partition:
nano /mnt/card/uEnv.txt

To disable the HDMI Cape, change the contents of uEnv.txt to:
optargs=quiet capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN

Save the file:
Ctrl-X, Y

Unmount the partition:
umount /mnt/card

Reboot the board:
shutdown -r now

Wait about 10 seconds and reconnect to the BeagleBone Black through SSH. To see what capes are enabled:
cat /sys/devices/bone_capemgr.*/slots

#
# Original slots setting
#
root@beaglebone:/media# cat /sys/devices/bone_capemgr.9/slots
 0: 54:PF---
 1: 55:PF---
 2: 56:PF---
 3: 57:PF---
 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
 5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI

#
# Should look like below after turning off the HDMI cape
#
root@beaglebone:/media# cat /sys/devices/bone_capemgr.9/slots
 0: 54:PF---
 1: 55:PF---
 2: 56:PF---
 3: 57:PF---
 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
 5: ff:P-O-- Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI

#
# Actual slots image after turning off the HDMI
#
 0: 54:PF---
 1: 55:PF---
 2: 56:PF---
 3: 57:PF---
 4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
 5: ff:P-O-- Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
 6: ff:P-O-- Bone-Black-HDMIN,00A0,Texas Instrument,BB-BONELT-HDMIN

Every line shows something like “P-O-L” or “P-O–”. The letter “L” means the Cape is enabled; no letter “L” means 
that it is disabled. You can see here that the HDMI Cape has been disabled, so pin 27 to 46 on header P8 are now 
available to use. 
=end

require 'beaglebone'
include Beaglebone
require 'singleton'
require 'forwardable'

class ByteAndAddress
    include Singleton
    
    def listCommands
        puts "" # Puts a new line for better readability...
        @uiCmds.each { 
            |cmdItem|
            puts "'#{cmdItem[0]}' - '#{cmdItem[1]}'"
        }
    
        # End of 'def listCommands'
    end
    
    def runUI
        initialize
        data = 0
        addr = 0
        while true
            # puts "#{data},#{addr}"
            #
            # Sets the strobe to low
            #
            @bbb_stb.digital_write(:LOW)
            
            #
            # Sets the address
            #
            if addr < 15
                addr = addr+1
            else
                addr = 0
            end
            # bits = addr.to_i(16).to_s(2)
            bits = addr.to_s(2)
            while bits.length < 4
                bits = "0"+bits
            end
            
            # puts "bit value = #{bits[0]},#{bits[1]},#{bits[2]},#{bits[3]} = #{bits}"
            if bits[3] == "1"
                @bbb_adr0.digital_write(:HIGH)
            else 
                @bbb_adr0.digital_write(:LOW)
            end
            
            if bits[2] == "1"
                @bbb_adr1.digital_write(:HIGH)
            else 
                @bbb_adr1.digital_write(:LOW)
            end
            
            if bits[1] == "1"
                @bbb_adr2.digital_write(:HIGH)
            else 
                @bbb_adr2.digital_write(:LOW)
            end
            
            if bits[0] == "1"
                @bbb_adr3.digital_write(:HIGH)
            else 
                @bbb_adr3.digital_write(:LOW)
            end
            
            #
            # Sets the data
            #
            if data < 255
                data = data+1
            else
                data = 0
            end
            # bits = data.to_i(16).to_s(2)
            bits = data.to_s(2)
            while bits.length < 8
                bits = "0"+bits
            end
            # puts "bit value = #{bits}"
            if bits[7] == "1"
                @bbb_data0.digital_write(:HIGH)
            else 
                @bbb_data0.digital_write(:LOW)
            end
            
            if bits[6] == "1"
                @bbb_data1.digital_write(:HIGH)
            else 
                @bbb_data1.digital_write(:LOW)
            end
            
            if bits[5] == "1"
                @bbb_data2.digital_write(:HIGH)
            else 
                @bbb_data2.digital_write(:LOW)
            end
            
            if bits[4] == "1"
                @bbb_data3.digital_write(:HIGH)
            else 
                @bbb_data3.digital_write(:LOW)
            end
            
            if bits[3] == "1"
                @bbb_data4.digital_write(:HIGH)
            else 
                @bbb_data4.digital_write(:LOW)
            end
            
            if bits[2] == "1"
                @bbb_data5.digital_write(:HIGH)
            else 
                @bbb_data5.digital_write(:LOW)
            end
            
            if bits[1] == "1"
                @bbb_data6.digital_write(:HIGH)
            else 
                @bbb_data6.digital_write(:LOW)
            end
            
            if bits[0] == "1"
                @bbb_data7.digital_write(:HIGH)
            else 
                @bbb_data7.digital_write(:LOW)
            end
            
            #
            # Sets the strobe to low
            #
            @bbb_stb.digital_write(:HIGH)
        end
=begin
userInput = ""
until userInput == "BYE" 
    listCommands
    print "-> "
    userInput = gets.chomp.upcase
    
    case userInput
    when "A"
        puts "\nUser ran a strobe"
        @bbb_stb.digital_write(:HIGH)
        @bbb_stb.digital_write(:LOW)
      
    when "B"
        puts "Set BBB_ADR."
        print "ADR value: "
        userInput = gets.chomp.upcase
        if userInput =~ /^[0-9A-F]+$/
            bits = userInput.to_i(16).to_s(2)
            while bits.length < 4
                bits = "0"+bits
            end
            puts "bit value = #{bits[0]},#{bits[1]},#{bits[2]},#{bits[3]} = #{bits}"
            if bits[3] == "1"
                @bbb_adr0.digital_write(:HIGH)
            else 
                @bbb_adr0.digital_write(:LOW)
            end
            
            if bits[2] == "1"
                @bbb_adr1.digital_write(:HIGH)
            else 
                @bbb_adr1.digital_write(:LOW)
            end
            
            if bits[1] == "1"
                @bbb_adr2.digital_write(:HIGH)
            else 
                @bbb_adr2.digital_write(:LOW)
            end
            
            if bits[0] == "1"
                @bbb_adr3.digital_write(:HIGH)
            else 
                @bbb_adr3.digital_write(:LOW)
            end
        else
            puts "#{userInput} is NOT a valid Hex value."
        end
        
    when "C"
        puts "Set BBB_DATA."
        print "DATA value: "
        userInput = gets.chomp.upcase
        if userInput =~ /^[0-9A-F]+$/
            bits = userInput.to_i(16).to_s(2)
            while bits.length < 8
                bits = "0"+bits
            end
            puts "bit value = #{bits}"
            if bits[7] == "1"
                @bbb_data0.digital_write(:HIGH)
            else 
                @bbb_data0.digital_write(:LOW)
            end
            
            if bits[6] == "1"
                @bbb_data1.digital_write(:HIGH)
            else 
                @bbb_data1.digital_write(:LOW)
            end
            
            if bits[5] == "1"
                @bbb_data2.digital_write(:HIGH)
            else 
                @bbb_data2.digital_write(:LOW)
            end
            
            if bits[4] == "1"
                @bbb_data3.digital_write(:HIGH)
            else 
                @bbb_data3.digital_write(:LOW)
            end
            
            if bits[3] == "1"
                @bbb_data4.digital_write(:HIGH)
            else 
                @bbb_data4.digital_write(:LOW)
            end
            
            if bits[2] == "1"
                @bbb_data5.digital_write(:HIGH)
            else 
                @bbb_data5.digital_write(:LOW)
            end
            
            if bits[1] == "1"
                @bbb_data6.digital_write(:HIGH)
            else 
                @bbb_data6.digital_write(:LOW)
            end
            
            if bits[0] == "1"
                @bbb_data7.digital_write(:HIGH)
            else 
                @bbb_data7.digital_write(:LOW)
            end
            
        else
            puts "#{userInput} is NOT a valid Hex value."
        end
        
    when "BYE"
        puts "User wants to exit the code."
    else
        puts "'#{userInput}' is not a valid command."
    end                
    # End of 'unless userInput == "BYE"'
end
puts "\nExiting code.\n\n"
=end
        # End of 'runUI'
    end

    def initialize
        system("cd /lib/firmware")
        
        # system("echo GPIO_P8_28_0x17 > /sys/devices/bone_capemgr.9/slots")
        @bbb_stb = GPIOPin.new(:P8_28, :OUT)
        @bbb_stb.digital_write(:LOW)         # Provide ground on pin bbb_stb - initial state.
        
        @bbb_adr0 = GPIOPin.new(:P8_35, :OUT) 
        @bbb_adr1 = GPIOPin.new(:P8_33, :OUT) 
        @bbb_adr2 = GPIOPin.new(:P8_31, :OUT) 
        @bbb_adr3 = GPIOPin.new(:P8_32, :OUT) 

        @bbb_data0 = GPIOPin.new(:P8_45, :IN) 
        @bbb_data1 = GPIOPin.new(:P8_46, :IN) 
        @bbb_data2 = GPIOPin.new(:P8_43, :IN) 
        @bbb_data3 = GPIOPin.new(:P8_44, :IN) 
        @bbb_data4 = GPIOPin.new(:P8_41, :IN) 
        @bbb_data5 = GPIOPin.new(:P8_42, :IN) 
        @bbb_data6 = GPIOPin.new(:P8_39, :IN) 
        @bbb_data7 = GPIOPin.new(:P8_40, :IN) 
=begin
        @bbb_data0 = GPIOPin.new(:P8_45, :OUT) 
        @bbb_data1 = GPIOPin.new(:P8_46, :OUT) 
        @bbb_data2 = GPIOPin.new(:P8_43, :OUT) 
        @bbb_data3 = GPIOPin.new(:P8_44, :OUT) 
        @bbb_data4 = GPIOPin.new(:P8_41, :OUT) 
        @bbb_data5 = GPIOPin.new(:P8_42, :OUT) 
        @bbb_data6 = GPIOPin.new(:P8_39, :OUT) 
        @bbb_data7 = GPIOPin.new(:P8_40, :OUT) 
=end
        @uiCmds = [
            ["A","Push one strobe."],
            ["B","Set BBB_ADR."],
            ["C","Set BBB_DATA."],
            ["BYE","Exits code"]
            ]
        # End of 'def initialize'
    end
    
    class << self
        extend Forwardable
        def_delegators :instance, *ByteAndAddress.instance_methods(false)
    end    
    # End of 'class ByteAndAddress'
end

ByteAndAddress.runUI


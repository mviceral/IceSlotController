This is the ruby code using c-code to access the GPIO2 port.

To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb

See the pattern in the scope once it's running.

Special note:  make sure the HDMI is dislodged.  Follow the instruction below

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

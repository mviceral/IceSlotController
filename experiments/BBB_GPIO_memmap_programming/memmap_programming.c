// 
// BeagleBone Black HDMI Cape must be disabled.  Follow the article below.
// 
// http://www.logicsupply.com/blog/2013/07/18/disabling-the-beaglebone-black-hdmi-cape/
// Disabling the BeagleBone Black HDMI Cape
// The HDMI port on the BeagleBone Black is implemented as a virtual cape. This virtual cape uses pins on the 
// expansion headers, limiting the available pins. If you don’t need HDMI you gain 20 more GPIO pins by disabling  
// the HDMI cape. Other reasons for disabling HDMI are to make UART 5 and the flow control for UART 3 and 4 
// available or to get more PWM pins. Follow the instructions below to disable the HDMI cape and make pins 27 to 46 
// on header P8 available.
// 
// Before you start, it’s always a good idea to update your BeagleBone Black with the latest Angstrom image.
// Use SSH to connect to the BeagleBone Black. You can use the web based GateOne SSH client or use PuTTY and connect 
// to beaglebone.local or 192.168.7.2
// 
// user name: root 
// password: <enter>
// 
// Mount the FAT partition:
// mount /dev/mmcblk0p1  /mnt/card
// 
// Edit the uEnv.txt on the mounted partition:
// nano /mnt/card/uEnv.txt
// 
// To disable the HDMI Cape, change the contents of uEnv.txt to:
// optargs=quiet capemgr.disable_partno=BB-BONELT-HDMI,BB-BONELT-HDMIN
// 
// Save the file:
// Ctrl-X, Y
// 
// Unmount the partition:
// umount /mnt/card
// 
// Reboot the board:
// shutdown -r now
// 
// Wait about 10 seconds and reconnect to the BeagleBone Black through SSH. To see what capes are enabled:
// cat /sys/devices/bone_capemgr.*/slots
// 
// #
// # Original slots setting
// #
// root@beaglebone:/media# cat /sys/devices/bone_capemgr.9/slots
//  0: 54:PF---
//  1: 55:PF---
//  2: 56:PF---
//  3: 57:PF---
//  4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
//  5: ff:P-O-L Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
// 
// #
// # Should look like below after turning off the HDMI cape
// #
// root@beaglebone:/media# cat /sys/devices/bone_capemgr.9/slots
//  0: 54:PF---
//  1: 55:PF---
//  2: 56:PF---
//  3: 57:PF---
//  4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
//  5: ff:P-O-- Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
// 
// #
// # Actual slots image after turning off the HDMI
// #
//  0: 54:PF---
//  1: 55:PF---
//  2: 56:PF---
//  3: 57:PF---
//  4: ff:P-O-L Bone-LT-eMMC-2G,00A0,Texas Instrument,BB-BONE-EMMC-2G
//  5: ff:P-O-- Bone-Black-HDMI,00A0,Texas Instrument,BB-BONELT-HDMI
//  6: ff:P-O-- Bone-Black-HDMIN,00A0,Texas Instrument,BB-BONELT-HDMIN
// 
// Every line shows something like “P-O-L” or “P-O–”. The letter “L” means the Cape is enabled; no letter “L” means 
// that it is disabled. You can see here that the HDMI Cape has been disabled, so pin 27 to 46 on header P8 are now 
// available to use. 
// 
//     Call the ruby code to enable the following pins to :OUT mode
//     GPIOPin.new(:P8_29, :OUT) # Strobe pin
//     GPIOPin.new(:P8_27, :OUT) # RdNWr pin - Read on high (Read not Write on high)
// 
//     The pins below are the address pins
//     GPIOPin.new(:P8_37, :OUT) 
//     GPIOPin.new(:P8_38, :OUT) 
//     GPIOPin.new(:P8_36, :OUT) 
//     GPIOPin.new(:P8_34, :OUT) 
// 
//     Call the ruby code to enable the following pins to :IN mode
//     The pins below are the data bus pins
//     @bbb_data0 = GPIOPin.new(:P8_45, :IN) 
//     @bbb_data1 = GPIOPin.new(:P8_46, :IN) 
//     @bbb_data2 = GPIOPin.new(:P8_43, :IN) 
//     @bbb_data3 = GPIOPin.new(:P8_44, :IN) 
//     @bbb_data4 = GPIOPin.new(:P8_41, :IN) 
//     @bbb_data5 = GPIOPin.new(:P8_42, :IN) 
//     @bbb_data6 = GPIOPin.new(:P8_39, :IN) 
//     @bbb_data7 = GPIOPin.new(:P8_40, :IN) 
// 
#include <sys/mman.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h> // sleep

#define GPIO_DATAOUT 0x13C
#define GPIO_SETDATAOUT 0x194
#define GPIO_CLEARDATAOUT 0x190
#define GPIO_OE 0x134
#define GPIO_DATAIN 0x138

int dataBusMask = 0xff<<6;
int AddrShift = 14;
int DataShift = 6;
#define GPIO2_START_ADDR 0x481AC000 /*0x44e108a4*/
#define GPIO2_END_ADDR   0x481AE000  /*0x44e10800 */
#define GPIO2_SIZE (GPIO2_END_ADDR - GPIO2_START_ADDR)

#define Strobe (1<<23) /*pin 22 for strobe*/
#define RdnWr (1<<22) // Read on High

volatile void *gpio_addr;
volatile unsigned int *gpio_AddrData_OE; // gpio_OE
volatile unsigned int *gpio_AddrData_DataOut;
volatile unsigned int *gpio_AddrData_DataIn;

void sendToDevice(int *addr,int *data){
    int dataHold;
    dataHold = 0; // Flush buffer.

    dataHold |= *addr<<AddrShift;
    dataHold |= *data<<DataShift;

    *gpio_AddrData_OE = 0; // All output is on...
    *gpio_AddrData_DataOut = dataHold;
    *gpio_AddrData_DataOut ^= Strobe; // The "write pulte"
}

int  getFromDevice(int *addr){
    int toBeReturned;
    int dataHold;
    dataHold = 0; // Flush buffer.
    dataHold |= *addr<<AddrShift;
    dataHold |= RdnWr;  // Extra op with no value...
    *gpio_AddrData_OE = 0; // All output is on...
    *gpio_AddrData_OE ^= dataBusMask; // It just needs it.
    *gpio_AddrData_DataOut = dataHold;

    toBeReturned = 0x000ff&*gpio_AddrData_DataIn>>DataShift;
    *gpio_AddrData_DataOut ^= RdnWr;    
    // toBeReturned = 0x00ff&&(toBeReturned>>6);
    // printf("oe=%08x data %08x\n",*gpio_AddrData_OE,toBeReturned);
    return toBeReturned;
}



void main (void) {
    int testCase = 0;
    int addr = 0;
    int data = 0;
    int strobe = 0;
    int fd = open("/dev/mem", O_RDWR);
    gpio_addr = mmap(0, GPIO2_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, GPIO2_START_ADDR);
    gpio_AddrData_OE = gpio_addr+GPIO_OE; // Sets the strobe register to output.
    gpio_AddrData_DataOut = gpio_addr+GPIO_DATAOUT;
    gpio_AddrData_DataIn = gpio_addr+GPIO_DATAIN;

    *gpio_AddrData_DataOut = Strobe;
    while (1) {
        
        if (data<255) data++;
        else data = 0;

        if (addr<15) addr++;
        else addr = 0;

        sendToDevice(&addr,&data);
        // sleep(1);
        testCase = getFromDevice(&addr);
        
        // printf("data %08x\n",testCase);
        // sleep(1);
    }
        // End of 'void main (void)'
}

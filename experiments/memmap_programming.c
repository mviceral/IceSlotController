/*
    Call the ruby code to enable the following pins to :IN mode
    @bbb_data0 = GPIOPin.new(:P8_45, :IN) 
    @bbb_data1 = GPIOPin.new(:P8_46, :IN) 
    @bbb_data2 = GPIOPin.new(:P8_43, :IN) 
    @bbb_data3 = GPIOPin.new(:P8_44, :IN) 
    @bbb_data4 = GPIOPin.new(:P8_41, :IN) 
    @bbb_data5 = GPIOPin.new(:P8_42, :IN) 
    @bbb_data6 = GPIOPin.new(:P8_39, :IN) 
    @bbb_data7 = GPIOPin.new(:P8_40, :IN) 
*/
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

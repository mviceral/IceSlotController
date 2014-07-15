/*
Ruby Objects to C Datatypes:

int	            NUM2INT(Numeric)	                (Includes type check)
int	            FIX2INT(Fixnum)	                    (Faster)
unsigned int	NUM2UINT(Numeric)	                (Includes type check)
unsigned int	FIX2UINT(Fixnum)	                (Includes type check)
long	        NUM2LONG(Numeric)	                (Includes type check)
long	        FIX2LONG(Fixnum)	                (Faster)
unsigned long	NUM2ULONG(Numeric)	                (Includes type check)
char	        NUM2CHR(Numeric or String)	        (Includes type check)
char *	        STR2CSTR(String)	
char *	        rb_str2cstr(String, int *length)	Returns length as well
double	        NUM2DBL(Numeric)

interest link:
http://elinux.org/EBC_Exercise_11b_gpio_via_mmap memory map - Rob's
https://github.com/petermancuso/bbb/commit/1ef2033db0b89adfd8c39e6041287b066428e007
https://groups.google.com/forum/#!topic/beagleboard/91ikp6Mxi0s  Mike's
http://rampic.com/beagleboneblack/ PRU - Programming Realtime Unit.
http://stackoverflow.com/questions/13124271/driving-beaglebone-gpio-through-dev-mem
https://github.com/majestik666/Beagle_GPIO/blob/master/Beagle_GPIO.cc
*/

// Include the Ruby headers and goodies
#include "ruby.h"
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


// Defining a space for information and references about the module to be stored internally
VALUE BusInterface = Qnil;

// Prototype for the initialization method - Ruby calls this, not you
void Init_businterface();

// Prototype for our method 'getFromDevice' - methods are prefixed by 'method_' here
VALUE method_getFromDevice(VALUE self, VALUE addrRuby);
void method_sendToDevice(VALUE self, VALUE addrRuby, VALUE addrData);
void method_initialize(VALUE self);

// The initialization method for this module
void Init_businterface() {
	BusInterface = rb_define_module("BusInterface");
	rb_define_method(BusInterface, "getFromDevice", method_getFromDevice, 1);
	rb_define_method(BusInterface, "sendToDevice", method_sendToDevice, 2);
	rb_define_method(BusInterface, "initialize", method_initialize, 0);
}

// Our 'getFromDevice' method.. it simply returns a value of '10' for now.
/*
VALUE method_getFromDevice(VALUE self) {
	int x = 10;
	return INT2NUM(x);
}
*/

VALUE method_getFromDevice(VALUE self, VALUE addrRuby) {
    int toBeReturned;
    int dataHold;
    dataHold = 0; // Flush buffer.
    dataHold |= FIX2INT(addrRuby)<<AddrShift;
    dataHold |= RdnWr;  // Extra op with no value...
    *gpio_AddrData_OE = 0; // All output is on...
    *gpio_AddrData_OE ^= dataBusMask; // It just needs it.
    *gpio_AddrData_DataOut = dataHold;

    toBeReturned = 0x000ff&*gpio_AddrData_DataIn>>DataShift;
    *gpio_AddrData_DataOut ^= RdnWr;    
    // toBeReturned = 0x00ff&&(toBeReturned>>6);
    // printf("oe=%08x data %08x\n",*gpio_AddrData_OE,toBeReturned);
	return INT2NUM(toBeReturned);
}

void method_sendToDevice(VALUE self, VALUE addrRuby, VALUE addrData) {
    int dataHold;
    dataHold = 0; // Flush buffer.

    dataHold |= FIX2INT(addrRuby)<<AddrShift;
    dataHold |= FIX2INT(addrData)<<DataShift;

    *gpio_AddrData_OE = 0; // All output is on...
    *gpio_AddrData_DataOut = dataHold;
    *gpio_AddrData_DataOut ^= Strobe; // The "write pulte"
}

void method_initialize(VALUE self) {
    int fd = open("/dev/mem", O_RDWR);
    gpio_addr = mmap(0, GPIO2_SIZE, PROT_READ | PROT_WRITE, MAP_SHARED, fd, GPIO2_START_ADDR);
    gpio_AddrData_OE = gpio_addr+GPIO_OE; // Sets the strobe register to output.
    gpio_AddrData_DataOut = gpio_addr+GPIO_DATAOUT;
    gpio_AddrData_DataIn = gpio_addr+GPIO_DATAIN;
}

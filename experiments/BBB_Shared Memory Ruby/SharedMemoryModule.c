// Include the Ruby headers and goodies
#include "ruby.h"
#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdio.h>

/*  3*842 The size of the memory we want to allocate case there are long error messages in the ThermalSite firmware.  382 is the current
    size of the data retrieved from BBB.
*/
#define SHMSZ 2526

unsigned char initialized = 0;
key_t key;
char *shm, *s;
int shmid;


// Defining a space for information and references about the module to be stored internally
VALUE SharedMemoryModule = Qnil;


// Prototype for the initialization method - Ruby calls this, not you
void Init_SharedMemoryModule();


// Prototype for our methods 'WriteDataToSharedMemory' - methods are prefixed by 'method_' here
VALUE method_WriteDataToSharedMemory(VALUE self, VALUE rubyStringParam);
VALUE method_GetDataFromSharedMemory(VALUE self);
void method_InitializeSharedMemory(VALUE self);


// The initialization method for this module
void Init_SharedMemoryModule() {
	SharedMemoryModule = rb_define_module("SharedMemoryModule");
	rb_define_method(SharedMemoryModule, "WriteDataToSharedMemory", method_WriteDataToSharedMemory, 1);
	rb_define_method(SharedMemoryModule, "GetDataFromSharedMemory", method_GetDataFromSharedMemory, 0);
	rb_define_method(SharedMemoryModule, "InitializeSharedMemory", method_InitializeSharedMemory, 0);
}

VALUE method_WriteDataToSharedMemory(VALUE self, VALUE rubyStringParam) {
    /*
        return values:
        0 - no error writing to memory.
        1 - not initialized.  Run the function InitializeVariables(), first.
        2 - sent String too long.  Not all data written in.
    */
    int ct=1;
    if (!initialized) {
        /*
            It's not initialized.
        */
        INT2NUM(1);
    }
    /*
        Set the first byte to let all the processes that the data is being updated.
    */
    while (*shm != (char)0)
        usleep(1); // Wait for a micro second until we get the buffer available for writing.
    *shm = (char)1;

    /*
     * Now put some things into the memory for the
     * other process to read.
     */
    s = (shm+1); /* +1 to skip the first character, since it's the flag that indicates memory is being written into. */
    char * sentString = StringValuePtr(rubyStringParam );
    while ( *(sentString) && ct++<SHMSZ) {
        *s++ = *(sentString++);
    }
    *s = '\0';
    
    /*
        Set the first byte to 0 to indicate that the memory is available for updating.
    */
    *shm = (char)0;
    
    if (ct < SHMSZ)
        INT2NUM(0);
    else 
        INT2NUM(2);
}


VALUE method_GetDataFromSharedMemory(VALUE self) {
    /*
        return values:
        null - which probably means that the InitializeVariables() is not called, or there is actually no data.
        valid character string pointer - the actual data in the shared memory.
        
        NOTE:
        Data can be changed if data pointer is given, with no care and of no knowledge how deep the pointer is.
        If data is pumped in more that what its allocated space, the code will blow up...
    */
    if (!initialized) {
        rb_str_new2("");
    }
    else {
        
        // Wait for a micro second until we get the buffer available for writing.    
        while (*shm != (char)0)
            usleep(1); 
        
        rb_str_new2(shm+1);
    }
}


void method_InitializeSharedMemory(VALUE self) {
    /*
     * We'll name our shared memory segment
     * "1234".
     */
    key = 1234;

    /*
     * Create the segment.
     */
    // printf("Page size %d\n",getpagesize());
    if ((shmid = shmget(key, SHMSZ, IPC_CREAT | 0666)) < 0) {
        perror("shmget");
        exit(1);
    }

    /*
     * Now we attach the segment to our data space.
     */
    if ((shm = shmat(shmid, NULL, 0)) == (char *) -1) {
        perror("shmat");
        exit(1);
    }
    
    initialized = 1;
    *shm = (char)0;
}


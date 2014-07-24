#include <sys/types.h>
#include <sys/ipc.h>
#include <sys/shm.h>
#include <stdio.h>


/*  3*842 The size of the memory we want to allocate case there are long error messages in the ThermalSite firmware.  382 is the current
    size of the data retrieved from BBB.
1234567890123456789012345678900123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789

*/
#define SHMSZ 2526

unsigned char initialized = 0;
key_t key;
char *shm, *s;
int shmid;
void InitializeVariables() {
    /*
     * We'll name our shared memory segment
     * "1234".
     */
    key = 1234;

    /*
     * Create the segment.
     */
     printf("Page size %d\n",getpagesize());
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

int WriteDataToSharedMemory(char * sentString) {
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
        return 1;
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
    while ( *(sentString) && ct++<SHMSZ) {
        *s++ = *(sentString++);
    }
    *s = '\0';
    
    /*
        Set the first byte to 0 to indicate that the memory is available for updating.
    */
    *shm = (char)0;
    
    if (ct < SHMSZ)
        return 0;
    else 
        return 2;
}

int CopySharedMemData(char * destinationString, int sizeOfDestinationStr){
    /*
        Never expose the address of the shared memory or users can muck with the memory and over write its allocated size
        and cause the code to blow up.
        
        return values:
        0 - no error reading from memory.
        1 - not initialized.  Run the function InitializeVariables(), first.
        2 - sizeOfDestinationStr is too short.  Not all data are copied.
    */
    int ct = 0;
    if (!initialized) {
        /*
            It's not initialized.
        */
        return 1;
    }
    
    // Wait for a micro second until we get the buffer available for writing.    
    while (*shm != (char)0)
        usleep(1); 
    
    s = (shm+1); /* +1 to skip the first character, since it's the flag that indicates memory is being written into. */
    while ( *(s) && ct++<(sizeOfDestinationStr-1) /* -1 for the null terminator. */) {
        *destinationString++ = *s++;
    }
    *destinationString = '\0';
    
    if ((ct-1)<(sizeOfDestinationStr-1))
        return 0;
    else
        return 2;
}

char * giveTheDataPointer() {
    /*
        return values:
        null - which probably means that the InitializeVariables() is not called, or there is actually no data.
        valid character string pointer - the actual data in the shared memory.
        
        NOTE:
        Data can be changed if data pointer is given, with no care and of no knowledge how deep the pointer is.
        If data is pumped in more that what its allocated space, the code will blow up...
    */
    if (!initialized) {
        return '\0';
    }
    else {
        
        // Wait for a micro second until we get the buffer available for writing.    
        while (*shm != (char)0)
            usleep(1); 
        
        return (shm+1);
    }
}

main()
{
    // char *testString = "abcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghijabcdefghij";
    char *testString = "1234567890123456789012345678900123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789";

    InitializeVariables();
    
    int result = WriteDataToSharedMemory(testString);
    switch (result) {
        case 0:
            printf("Data written in.\n");
            break;
        case 1:
            printf("ERROR Shared memory not initialized.\n");
            break;
        case 2:
            printf("Data too long.  Not all were written in.\n");
            break;
        default:
            printf("result = '%d'\n",result);
            break;
    }
    
    
    
    char hold[2500];
    result = CopySharedMemData(hold,2500);
    switch (result) {
        case 0:
            printf("Data read correctly.\n");
            break;
        case 1:
            printf("ERROR Shared memory not initialized.\n");
            break;
        case 2:
            printf("Data too long.  Not all were read in.\n");
            break;
        default:
            printf("result = '%d'\n",result);
            break;
    }
    printf("hold='%s'\n",hold);
    
    
    printf("The pointer content='%s'\n",giveTheDataPointer());

}
The purpose of this experiment is to have a shared memory for two processes: BBB sampling dut data, and sending sampled BBB data to the
PC.

SharedMemoryModule is needed because 'sampling data' will write data to this memory map.  The 'sending data' process will take the data 
from this memory and ship it to the PC, and once the PC sends back and acknowledge that it saved the sent data, the data sitting in the
shared memory will also be saved into the local SD drive of BBB and remove the data instace from memory.

This step is to minimize the "erase cycle" on the SD drive of the BBB, thus suppose to prolong the lifespan of the SD memory.

gcc shm_client.c -o client
gcc shm_server.c -o server

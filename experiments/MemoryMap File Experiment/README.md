The purpose of this experiment is to have a shared memory for two processes: BBB sampling dut data, and sending sampled BBB data to the PC.

MemoryMap is needed because sampling data will write data to this memory map.  The sending data will take the data, and ship it to the PC, 
and once the PC sends back and acknowledge that it saved the sent data, the data sitting in the memory map will also be saved into the 
local SD drive of BBB and remove the data instace from memory map.

This step is to minimize the "erase cycle" on the SD drive of the BBB, thus prolonging the lifespan of the SD memory.

gcc shm_client.c -o client
gcc shm_server.c -o server
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
The purpose of this code is to have a shared memory for BBB writing to the GPIO and another website that displays
the values written in GPIO2.

SharedMemoryModuleGPIO is needed for diagnostics of what is happening in the GPIO2.

To run:
clear; ruby extconf.rb ; make; ruby RubyTestSharedMemoryBbbGpio2.rb

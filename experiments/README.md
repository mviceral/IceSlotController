sandBox
=======
July 7, 2014 Code changes
readUART1.rb was modified to replace values of baud rate as a variable so code is more maintanable.  Added code to 
create dbase table for keeping track of activities like logging, version request, resetting the ThermalSite, and 
setting the set point temperature.  But nutshell, it's dead code because the firmware is now changed and the code 
does not receive any more status every second.

Made a copy of readUART1.rb to pollData.rb.  pollData.rb reads the ThermalSite device every set interval (second) 
and records the log into a dababase using sqlite3.  The table it uses is dynamicdata1.db, table name dynamicdata.

ThermalSite.rb - is a testbed software to see if the ThermalSite device was responding properly on the 'status 
request:S?' (dynamic data request), 'version request:V?' (static data request), set temperature command 'T:###.###', 
and Reset command 'R?'.

Code snippets 
openTtyO1Port.exe is created by compiling the serial.cpp code. "g++ -o openTtyO1Port.exe serial.cpp".  For some reason, the ruby code will 
not run if this c code executable is not called within the ruby script steps for accessing UART1 in readUART1.rb file.

readAIN4.rb is a code snippet for reading the AIN4.

readUART1.rb is the code the reads the UART1, and displays that data.  It's in the middle of writing code to start saving the read data into 
a database.  The database is actaully using the SD card.  

serial.cpp and serialib.h are the c++ code for producing the openTtyO1Port.exe executable.  I got it somewhere.

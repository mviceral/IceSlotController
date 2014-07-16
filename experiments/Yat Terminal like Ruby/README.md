To see what the ThermalSite (TS) is sending through UART port, run readUART1.rb with ruby on its own terminal:
ruby readUART1.rb

To send TS commands on the TS device through UART port, run the script on another terminal:

ruby writeUART1.rb <cmd>

    Where <cmd> can be 
      S? - which will return the status (dynamic data: ambient temp, current temp, etc)
      V? - Which will return the version (static temp)
      
      T: - Which sets up the TS to take in a number in this specific format ###.### for the next UART write command
           to set the new setpoint temperature.
           
      R? - Reboots the TS.

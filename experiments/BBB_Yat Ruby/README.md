To see what the ThermalSite (TS) is sending through UART port, run readUART1.rb with ruby on its own terminal:
ruby readUART1.rb

To send TS commands on the TS device through UART port, run the script on another terminal:

ruby writeUART1.rb <cmd>

    Where <cmd> can be 
    S?  ( request current operation variables )
    
    Gives back a string of data for DYNAMIC data
    
    Example: @1,24.875,23.955,0,12,Ok
    
    (Mode run/stop),(Controller Temp),(DUT Temp),(COOL/HEAT mode),(PWM output), (Status, OK, or any alarm condition / sensor issue)
    
     
    
    V? ( request current settings variables )
    
    Gives back a string of data for STATIC data
    
    Example: @25.000,RTD100,p6.00 i0.60 d0.15,mpo255, cso101, V2.2
    
    (Temperature Set point), (Sensor Type), (PID p), (PID i), (PID d), (MaxOutputPwm), (CoolStopOuput), (Firmware Version)
    
     
    
    L! (turn ON automatic S? request on for terminal logging 1 per second)
    
    Send this command to enable terminal mode logging
    
     
    
    N! (turn OFF automatic S? request on for terminal logging 1 per second)
    
    Send this command to disable terminal mode logging ( default is off )
    
     
    
    T: (FloatValue) example 125.000 = 125C
    
    Temperature set point
    
     
    
    P: (FloatValue) example 6.000
    
    PID Proportional value
    
     
    
    I: (FloatValue) example 0.600
    
    PID Integral value
    
     
    
    D: (FloatValue) example 0.150
    
    PID Derivative value
    
     
    
    C: (Value) 0-255
    
    Cooling PWM override for STOP mode
    
     
    
    H: (Value) 0-255
    
    Cooling PWM override for RUN mode MAX PWM value
    
 
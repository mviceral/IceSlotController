#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'GPIO2'
require 'beaglebone'
include Beaglebone

# Clear the screen
puts "\e[H\e[2J"
puts "Starting application"
aMuxMultiplier = Hash.new
aMuxMultiplier[32] = 2.3
aMuxMultiplier[33] = 2.3
aMuxMultiplier[34] = 2.3
aMuxMultiplier[35] = 2.3
aMuxMultiplier[36] = 2.3
aMuxMultiplier[37] = 2.3
aMuxMultiplier[38] = 2.3
aMuxMultiplier[39] = 2.3
aMuxMultiplier[40] = 4.01
aMuxMultiplier[41] = 4.01
aMuxMultiplier[42] = 4.01
aMuxMultiplier[43] = 4.01
aMuxMultiplier[44] = 4.01
aMuxMultiplier[45] = 9.66
aMuxMultiplier[46] = 9.66
aMuxMultiplier[47] = 20.1
gpio2 = GPIO2.new
# gpio2.testWithScope
muxInput = ""


while (muxInput == "x" || muxInput == "X") == false
    puts "'A' - to display Volts for AMUX Channel 32-47:"
    puts "'B' - to display Slot P5V, P3V3, P1V8, CALREF :"
    puts "Input mux (0-47)"
    puts "'x' - to exit:"
    muxInput = gets.chomp  
    if  muxInput == "a" || muxInput == "A"
        aMux = 32
        pAin = AINPin.new(:P9_33)
=begin        
        while aMux<48
            gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
            # sleep(1.0)
            retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
            # pAin = AINPin.new(:P9_33)
            readValue = pAin.read
            puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*aMuxMultiplier[aMux]/1000.0).round(4)} V'"
            # puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*aMuxMultiplier[aMux]/1000.0).round(4)} V'"
            aMux += 1
        end
=end        
        aMux = 40
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"

        aMux = 41
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"

        aMux = 42
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"


        aMux = 43
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"

        aMux = 44
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"

        aMux = 45
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*9.66/1000.0).round(4)} V'"

        aMux = 46
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*9.66/1000.0).round(4)} V'"

        aMux = 47
        gpio2.setGPIO2(ANA_MEAS4_SEL_xD, aMux)
        retval = gpio2.getGPIO2(ANA_MEAS4_SEL_xD)
        readValue = pAin.read
        puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*20.1/1000.0).round(4)} V'"
        puts ""
        puts ""
    elsif  muxInput == "b" || muxInput == "B"
        pAin = AINPin.new(:P9_39)
        readValue = pAin.read
        puts "AIN0 (P9_39) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"
        
        pAin = AINPin.new(:P9_40)
        readValue = pAin.read
        puts "AIN1 (P9_40) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
        
        pAin = AINPin.new(:P9_37)
        readValue = pAin.read
        puts "AIN2 (P9_37) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
        
        pAin = AINPin.new(:P9_38)
        readValue = pAin.read
        puts "AIN3 (P9_38) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue/1000.0).round(4)} V'"
        
        pAin = AINPin.new(:P9_36)
        readValue = pAin.read
        puts "AIN5 (P9_36) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue/1000.0).round(4)} V'"
        
        pAin = AINPin.new(:P9_35)
        readValue = pAin.read
        puts "AIN6 (P9_35) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue/1000.0).round(4)} V'"
        puts ""
        puts ""
    elsif muxInput == "x" || muxInput == "X"
        puts "Exitting code."
    else 
        mux = muxInput.to_i
        if 0 <= mux && mux <= 47
            gpio2.setGPIO2(ANA_MEAS4_SEL_xD, mux)
            sleep(0.001)
            readValue = AIN.read(:P9_33)
            puts "AIN4 (P9_33) AMUX CH (#{mux}) = '#{readValue}'"
            puts ""
            puts ""
        else
            puts "Number too large."
        end
    end
end

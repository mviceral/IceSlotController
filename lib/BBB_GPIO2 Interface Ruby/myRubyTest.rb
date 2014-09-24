#
# To run:
# clear; ruby extconf.rb ; make; ruby myRubyTest.rb
#
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
require_relative 'GPIO2'
require 'beaglebone'
include Beaglebone


class TestBench
    def readRawAin(pAin)
        @lastReading = "RawAin"
        return pAin.read
    end

    def getMuxValue(aMuxParam)
        a=0
        @gpio2.setGPIO2(GPIO2::ANA_MEAS4_SEL_xD, aMuxParam)
        
        numTimes = 5
        if @lastReading != "Mux"
            @lastReading = "Mux"
            numTimes = 10
        else
            numTimes = 1
        end
        
        while a<numTimes
            readValue = @pAinMux.read
            a += 1
        end
        return @pAinMux.read
    end
    
    def runTest
# Clear the screen
        puts "\e[H\e[2J"
        puts "Starting application"
        aMuxMultiplier = Hash.new
        aMuxMultiplier[0] = 20
        aMuxMultiplier[1] = 20
        aMuxMultiplier[2] = 20
        aMuxMultiplier[3] = 20
        aMuxMultiplier[4] = 20
        aMuxMultiplier[5] = 20
        aMuxMultiplier[6] = 20
        aMuxMultiplier[7] = 20
        aMuxMultiplier[8] = 20
        aMuxMultiplier[9] = 20
        aMuxMultiplier[10] = 20
        aMuxMultiplier[11] = 20
        aMuxMultiplier[12] = 20
        aMuxMultiplier[13] = 20
        aMuxMultiplier[14] = 20
        aMuxMultiplier[15] = 20
        aMuxMultiplier[16] = 20
        aMuxMultiplier[17] = 20
        aMuxMultiplier[18] = 20
        aMuxMultiplier[19] = 20
        aMuxMultiplier[20] = 20
        aMuxMultiplier[21] = 20
        aMuxMultiplier[22] = 20
        aMuxMultiplier[23] = 20
        aMuxMultiplier[24] = 2
        aMuxMultiplier[25] = 5
        aMuxMultiplier[26] = 5
        aMuxMultiplier[27] = 5
        aMuxMultiplier[28] = 5
        aMuxMultiplier[29] = 5
        aMuxMultiplier[30] = 10
        aMuxMultiplier[31] = 10
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
        @gpio2 = GPIO2.new
        # gpio2.testWithScope
        muxInput = ""
        
        
        while (muxInput == "x" || muxInput == "X") == false
            puts "'A' - to display Volts for AMUX Channel 32-47:"
            puts "'B' - to display Slot P5V, P3V3, P1V8, CALREF :"
            puts "Input mux (0-47)"
            puts "'x' - to exit:"
            muxInput = gets.chomp  
            if  muxInput == "a" || muxInput == "A"
                beginT = Time.now
                aMux = 0
                @pAinMux = AINPin.new(:P9_33)
                while aMux<48
                    readValue = getMuxValue(aMux)
                    puts "AMUX CH (0x#{aMux.to_s(16)}/#{aMux}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*aMuxMultiplier[aMux]/1000.0).round(4)} V'"
                    # puts "retval= '0x#{retval.to_s(16)}' AMUX CH (0x#{aMux.to_s(16)}) AIN4='#{readValue/1000.0} V' - Adjusted: '#{(readValue*aMuxMultiplier[aMux]/1000.0).round(4)} V'"
                    aMux += 1
                end
                puts "Total time = #{Time.now.to_f-beginT.to_f}"
                puts ""
                puts ""
            elsif  muxInput == "b" || muxInput == "B"
                readValue = readRawAin(AINPin.new(:P9_39))
                # sleep(2)
                puts "AIN0 (P9_39) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*4.01/1000.0).round(4)} V'"
                
                readValue = readRawAin(AINPin.new(:P9_40))
                # sleep(2)
                puts "AIN1 (P9_40) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
                
                readValue = readRawAin(AINPin.new(:P9_37))
                # sleep(2)
                puts "AIN2 (P9_37) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
                
                readValue = readRawAin(AINPin.new(:P9_38))
                # sleep(2)
                puts "AIN3 (P9_38) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
                
                readValue = readRawAin(AINPin.new(:P9_36))
                # sleep(2)
                puts "AIN5 (P9_36) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
                
                readValue = readRawAin(AINPin.new(:P9_35))
                puts "AIN6 (P9_35) = '#{readValue/1000.0} V' - Adjusted: '#{(readValue*2.3/1000.0).round(4)} V'"
                puts ""
                puts ""
            elsif muxInput == "x" || muxInput == "X"
                puts "Exitting code."
            else 
                mux = muxInput.to_i
                if 0 <= mux && mux <= 47
                    gpio2.setGPIO2(GPIO2::ANA_MEAS4_SEL_xD, mux)
                    readValue = AIN.read(:P9_33)
                    puts "AIN4 (P9_33) AMUX CH (#{mux}(#{mux.to_s(16)})) = '#{readValue}'"
                    puts ""
                    puts ""
                else
                    puts "Number too large."
                end
            end
        end
    end
end

tester = TestBench.new
tester.runTest

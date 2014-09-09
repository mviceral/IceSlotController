# require_relative 'AllDuts'
require_relative '../lib/SharedMemory'
# ----------------- Bench mark string length so it'll fit on GitHub display without having to scroll ----------------
class DutObj
    FaultyTcu = "Faulty Tcu"        

    def initialize()
        @statusResponse = Array.new(TOTAL_DUTS_TO_LOOK_AT)
        @sharedMem = SharedMemory.new()
        # End of 'def initialize()'
    end
    
    def getTcuStatus(dutNumParam,uart1Param,gPIO2)
        gPIO2.etsRxSel(dutNumParam)
        tbr = "" # tbr - to be returned
        uartStatusCmd = "S?\n"
        uart1Param.write("#{uartStatusCmd}");
        keepLooping = true

        #
        # Code block for ensuring that status request is sent and the expected response is received.
        #
        while keepLooping
            begin
                complete_results = Timeout.timeout(0.1) do      
                    uart1Param.each_line { 
                        |line| 
                        tbr = line
                        keepLooping = false     # loops out of the keepLooping loop.
                        break if line =~ /^@/   # loops out of the each_line loop.
                    }
                end
                rescue Timeout::Error
                    puts "Timed out Error. dutNumParam=#{dutNumParam}"
                    uart1Param.disable   # uart1Param variable is now dead cuz it timed out.
                    uart1Param = UARTDevice.new(:UART1, 115200)  # replace the dead uart variable.
                    tbr = FaultyTcu
=begin                
                    puts "Flushing out ThermalSite uart."
                    keepLooping2 = true
                    while keepLooping2
                        begin
                            complete_results = Timeout.timeout(1) do      
                                uart1Param.each_line { 
                                    |line| 
                                    puts "' -- ${line}"
                                }
                        end
                        rescue Timeout::Error
                            puts "Done flushing out ThermalSite uart."
                            uart1Param.disable   # uart1Param variable is now dead cuz it timed out.
                            uart1Param = UARTDevice.new(:UART1, 115200)  # replace the dead uart variable.
                            keepLooping2 = false     # loops out of the keepLooping loop.
                        end
                    end
    
    
                    uart1Param.write("#{uartStatusCmd}");    # Resend the status request command.
        
                    #
                    # Place code here for handling hiccups.
                    #
=end                
            end
            return tbr
        end
    end
    
    def poll(dutNumParam, uart1Param,gPIO2)
        #puts "within poll. dutNumParam=#{dutNumParam}"
        # gets
        @statusResponse[dutNumParam] = getTcuStatus(dutNumParam, uart1Param,gPIO2)
        puts "dutNumParam=#{dutNumParam} @statusResponse[dutNumParam]=#{@statusResponse[dutNumParam]} #{__LINE__}-#{__FILE__}"
        #puts "Leaving poll. dutNumParam=#{dutNumParam}"
    end

    def saveAllData(timeNowParam)
        dutNum = 0;
        allDutData = "";
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do
            #
            # Get the string index [1..-1] because we're skipping the first character '@'
            # Parse the data out.
            #
            if @statusResponse[dutNum].nil? == false
                # Old code
                # SD card just got plugged in.  DutObj got re-initialized.
                #
                # puts "@statusResponse[dutNum].nil? == true - skipping out of town. #{__FILE__} - #{__LINE__}"
                # return
                allDutData += "|#{dutNum}"
                allDutData += @statusResponse[dutNum]
            end
            # puts "@statusResponse[#{dutNum}] = #{@statusResponse[dutNum]}"
            dutNum +=1;
            # End of 'while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do'
        end            
		
        timeNow = Time.now.to_i
		allDutData = "-BBB#{timeNow}"+allDutData
		# puts "Poll A #{Time.now.inspect}"
        @sharedMem.WriteDataTcu(allDutData,"#{__LINE__}-#{__FILE__}")
		# puts "Poll B #{Time.now.inspect}"
        
        # End of 'def poll()'
    end

    # End of 'class DutObj'
end


# require_relative 'AllDuts'
require_relative '../BBB_Shared Memory Ruby/SharedMemory'

class DutObj

    def initialize(createLogInterval_UnitsInHoursParam, parentParam)
        @statusResponse = Array.new(TOTAL_DUTS_TO_LOOK_AT)
        SharedMemory.Initialize()
        # End of 'def initialize()'
    end
    
    def poll(dutNumParam, uart1Param)
        puts "within poll. dutNumParam=#{dutNumParam}"
        # gets
        uartStatusCmd = "S?\n"
        uart1Param.write("#{uartStatusCmd}");
        keepLooping = true
        
        #
        # Code block for ensuring that status request is sent and the expected response is received.
        #
        while keepLooping
            begin
                complete_results = Timeout.timeout(1) do      
                    uart1Param.each_line { 
                        |line| 
                        @statusResponse[dutNumParam] = line
                        keepLooping = false     # loops out of the keepLooping loop.
                        break if line =~ /^@/   # loops out of the each_line loop.
                    }
            end
            rescue Timeout::Error
                puts "Timed out Error. dutNumParam=#{dutNumParam}"
                uart1Param.disable   # uart1Param variable is now dead cuz it timed out.
                uart1Param = UARTDevice.new(:UART1, 115200)  # replace the dead uart variable.
                uart1Param.write("#{uartStatusCmd}");    # Resend the status request command.
    
                #
                # Place code here for handling hiccups.
                #
            end
        end
        puts "Leaving poll. dutNumParam=#{dutNumParam}"
    end

    def saveAllData(timeNowParam)
        dutNum = 0;
        allDutData = "";
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do
            #
            # Get the string index [1..-1] because we're skipping the first character '@'
            # Parse the data out.
            #
            if @statusResponse[dutNum].nil? == true
                #
                # SD card just got plugged in.  DutObj got re-initialized.
                #
                # puts "@statusResponse[dutNum].nil? == true - skipping out of town. #{__FILE__} - #{__LINE__}"
                return
            end
            # puts "@statusResponse[#{dutNum}] = #{@statusResponse[dutNum]}"
            allDutData += "|#{dutNum}"
            allDutData += @statusResponse[dutNum]
            dutNum +=1;
            # End of 'while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do'
        end            
		
        timeNow = Time.now.to_i
		allDutData = "-BBB#{timeNow}"+allDutData
		puts "Poll A #{Time.now.inspect}"
        SharedMemory.WriteData(allDutData)
		puts "Poll B #{Time.now.inspect}"
        
        # End of 'def poll()'
    end

    # End of 'class DutObj'
end


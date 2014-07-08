require_relative 'DutObj'

class AllDuts
    attr_accessor :duts
    attr_accessor :hashIndexOfDut

    def initialize(createLogInterval_UnitsInHoursParam)
        @duts = Array.new
        dutNum = 0;
        while  dutNum<TOTAL_DUTS_TO_LOOK_AT  do
            @duts.push(DutObj.new(dutNum,createLogInterval_UnitsInHoursParam,duts))
            # puts "dutNum=#{dutNum}"
            dutNum +=1;
        end            
        hashIndexOfDut = Hash[duts.map.with_index.to_a]
    end
    
    def hashIndexOfDut
        if @hashIndexOfDut.nil?
            puts "@hashIndexOfDut is nil.  Initializing..."
            initialize
        end
        @hashIndexOfDut
    end
    
    def getDut(dut)
        # Replace with doing the work to get the dut'th current value
        # Use a function to get the temperature instead of the self.fetch
        # if @duts.nil?
        #    puts "duts is still nil"
        #else
        #    puts "Not nil anymore."
        #end
        #puts "Within getDut dut.statusDbFile=#{@duts[dut].statusDbFile}"
        #gets
        @duts[dut]
    end

    #def[]=(dut,v)
      # Replace this with the work to set the temperature for the ith
      # dut Use a function to set the temperature
      
    #  self.insert(dut,v)
    #end
    
    # End of 'class Allduts'
end

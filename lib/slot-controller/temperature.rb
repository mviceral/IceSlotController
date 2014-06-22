require 'singleton'

module SlotController
  class OverloadedArray < Array
    def [](i)
      self.fetch(i)
    end

    def[]=(i,v)
      self.insert(i,v)
    end
  end
  
  class Temperature
    include Singleton
    

    attr_accessor :value
    attr_accessor :min
    attr_accessor :max
    
    NUM_DUTS = 24
    MIN_DEFAULT = -10
    MAX_DEFUALT = 200

    def initialize

      # Anything you need to do to initialize the beaglebone and slot
      # controler board to be able to get / set temperateu

      # Default Min/Max
      @min = (0..24).map { |d| -10 }
      @max = (0..24).map { |d| 200 }
      @value = OverloadedArray.new
    end

  end
end

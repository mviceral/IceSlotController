require 'beaglebone'
require 'singleton'
require 'forwardable'

module SlotController
  class TemperatureDut < Array
    def [](dut)
      # Replace with doing the work to get the dut'th current value
      # Use a function to get the temperature instead of the self.fetch
      self.fetch(dut)
    end

    def[]=(dut,v)
      # Replace this with the work to set the temperature for the ith
      # dut Use a function to set the temperature
      
      self.insert(dut,v)
    end
  end
  
  class Temperature
    include Singleton
    

    attr_accessor :value
    attr_accessor :min
    attr_accessor :max
    
    NUM_DUTS = 24
    MIN_DEFAULT = -10
    MAX_DEFAULT = 200

    def initialize

      # Anything you need to do to initialize the beaglebone and slot
      # controler board to be able to get / set temperateu

      # Default Min/Max
      @min = (0..NUM_DUTS).map { |d| MIN_DEFAULT }
      @max = (0..NUM_DUTS).map { |d| MAX_DEFAULT }
      @value = TemperatureDut.new
    end

    class << self
      extend Forwardable
      def_delegators :instance, *Temperature.instance_methods(false)
    end
  end
end

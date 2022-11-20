module PDK
  class Config
    # A collection of predefined validators for use with {PDK::Config::Value}.
    #
    # @example
    #   value :enabled do
    #     validate PDK::Config::Validator.boolean
    #   end
    module Validator
      # @return [Hash{Symbol => [Proc,String]}] a {PDK::Config::Value}
      #   validator that ensures that the value is either a TrueClass or
      #   FalseClass.
      def self.boolean
        {
          proc:    ->(value) { [true, false].include?(value) },
          message: 'must be a boolean: true or false',
        }
      end

      # @return [Hash{Symbol => [Proc,String]}] a {PDK::Config::Value}
      #   validator that ensures that the value is a String that matches the
      #   regex for a version 4 UUID.
      def self.uuid
        {
          proc:    ->(value) { value.match(%r{\A\h{8}(?:-\h{4}){3}-\h{12}\z}) },
          message: 'must be a version 4 UUID',
        }
      end
    end
  end
end

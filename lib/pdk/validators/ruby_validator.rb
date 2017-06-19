require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/validators/ruby/rubocop'

module PDK
  module Validate
    class RubyValidator < BaseValidator
      def self.name
        'ruby'
      end

      def self.ruby_validators
        [Rubocop]
      end

      def self.invoke(options = {})
        results = {}
        ruby_validators.each do |validator|
          output = validator.invoke(options)
          results.merge!(validator.name.to_s => output)
        end
        results
      end
    end
  end
end

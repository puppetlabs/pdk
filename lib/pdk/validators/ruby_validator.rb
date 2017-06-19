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
        # FIXME: deal with nested validators, this is a mess right now
        result = {
          exit_code: 0,
          stdout: '',
          stderr: '',
        }

        # Merge the results of each sub-validator into a single result for now.
        ruby_validators.each do |validator|
          output = validator.invoke(options)
          result[:exit_code] = 1 unless output[:exit_code].zero?
          result[:stdout] << output[:stdout]
          result[:stderr] << output[:stderr]
        end

        result
      end
    end
  end
end

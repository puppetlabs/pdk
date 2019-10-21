require 'pdk'

module PDK
  module Validate
    class RubyValidator < BaseValidator
      def self.name
        'ruby'
      end

      def self.ruby_validators
        [Rubocop]
      end

      def self.invoke(report, options = {})
        exit_code = 0

        ruby_validators.each do |validator|
          exit_code = validator.invoke(report, options)
          break if exit_code != 0
        end

        exit_code
      end
    end
  end
end

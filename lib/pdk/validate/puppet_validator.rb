require 'pdk'

module PDK
  module Validate
    class PuppetValidator < BaseValidator
      def self.name
        'puppet'
      end

      def self.puppet_validators
        [PuppetSyntax, PuppetLint, PuppetEPP]
      end

      def self.invoke(report, options = {})
        exit_code = 0

        puppet_validators.each do |validator|
          exit_code = validator.invoke(report, options)
          break if exit_code != 0
        end

        exit_code
      end
    end
  end
end

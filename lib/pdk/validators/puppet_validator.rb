require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/validators/puppet/puppet_lint.rb'
require 'pdk/validators/puppet/puppet_parser.rb'

module PDK
  module Validate
    class PuppetValidator < BaseValidator
      def self.name
        'puppet'
      end

      def self.puppet_validators
        [PuppetLint, PuppetParser]
      end

      def self.invoke(options = {})
        results = {}
        puppet_validators.each do |validator|
          output = validator.invoke(options)
          results.merge!(validator.name.to_s => output)
        end
        results
      end
    end
  end
end

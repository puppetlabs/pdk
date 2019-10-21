require 'pdk'

module PDK
  module Validate
    class YAMLValidator < BaseValidator
      def self.name
        'yaml'
      end

      def self.validators
        [
          PDK::Validate::YAML::Syntax,
        ]
      end

      def self.invoke(report, options = {})
        exit_code = 0

        validators.each do |validator|
          exit_code = validator.invoke(report, options)
          break if exit_code != 0
        end

        exit_code
      end
    end
  end
end

require 'pdk'

module PDK
  module Validate
    class TasksValidator < BaseValidator
      def self.name
        'tasks'
      end

      def self.metadata_validators
        [
          Tasks::Name,
          Tasks::MetadataLint,
        ]
      end

      def self.invoke(report, options = {})
        exit_code = 0

        metadata_validators.each do |validator|
          exit_code = validator.invoke(report, options)
          break if exit_code != 0
        end

        exit_code
      end
    end
  end
end

# frozen_string_literal: true

require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validate/base_validator'
require 'pdk/validate/metadata/metadata_json_lint'
require 'pdk/validate/metadata/metadata_syntax'
require 'pdk/validate/metadata/task_metadata_lint'

module PDK
  module Validate
    class MetadataValidator < BaseValidator
      def self.name
        'metadata'
      end

      def self.metadata_validators
        [MetadataSyntax, MetadataJSONLint, TaskMetadataLint]
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

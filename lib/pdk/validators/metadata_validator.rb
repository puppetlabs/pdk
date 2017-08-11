require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/validators/metadata/metadata_json_lint'
require 'pdk/validators/metadata/metadata_syntax'

module PDK
  module Validate
    class MetadataValidator < BaseValidator
      def self.name
        'metadata'
      end

      def self.metadata_validators
        [MetadataSyntax, MetadataJSONLint]
      end

      def self.invoke(report, options = {})
        exit_code = 0

        if options[:targets] && options[:targets] != []
          PDK.logger.info(_('metadata validator only checks metadata.json. The specified files will be ignored: %{targets}') % { targets: options[:targets].join(', ') })
          options.delete(:targets)
        end

        metadata_validators.each do |validator|
          exit_code = validator.invoke(report, options)
          break if exit_code != 0
        end

        exit_code
      end
    end
  end
end

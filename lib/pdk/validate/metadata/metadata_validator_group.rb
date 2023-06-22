require 'pdk'

module PDK
  module Validate
    module Metadata
      class MetadataValidatorGroup < ValidatorGroup
        def name
          'metadata'
        end

        def validators
          [
            MetadataSyntaxValidator,
            MetadataJSONLintValidator,
            MetadataDependencyValidator
          ].freeze
        end
      end
    end
  end
end

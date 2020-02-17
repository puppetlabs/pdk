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
          ].freeze
        end
      end
    end
  end
end

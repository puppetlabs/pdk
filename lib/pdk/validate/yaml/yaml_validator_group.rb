require 'pdk'

module PDK
  module Validate
    module YAML
      class YAMLValidatorGroup < ValidatorGroup
        def name
          'yaml'
        end

        def validators
          [
            YAMLSyntaxValidator,
          ].freeze
        end
      end
    end
  end
end

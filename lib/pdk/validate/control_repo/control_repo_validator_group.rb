require 'pdk'

module PDK
  module Validate
    module ControlRepo
      class ControlRepoValidatorGroup < ValidatorGroup
        def name
          'control-repo'
        end

        def valid_in_context?
          context.is_a?(PDK::Context::ControlRepo)
        end

        def validators
          [
            EnvironmentConfValidator,
          ].freeze
        end
      end
    end
  end
end

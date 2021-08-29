require 'pdk'

module PDK
  module Validate
    module Puppet
      class PuppetValidatorGroup < ValidatorGroup
        def name
          'puppet'
        end

        def validators
          [
            PuppetSyntaxValidator,
            PuppetPlanSyntaxValidator,
            PuppetLintValidator,
            PuppetEPPValidator,
          ].freeze
        end
      end
    end
  end
end

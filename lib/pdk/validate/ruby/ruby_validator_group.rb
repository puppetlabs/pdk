require 'pdk'

module PDK
  module Validate
    module Ruby
      class RubyValidatorGroup < ValidatorGroup
        def name
          'ruby'
        end

        def validators
          [
            RubyRubocopValidator,
          ].freeze
        end
      end
    end
  end
end

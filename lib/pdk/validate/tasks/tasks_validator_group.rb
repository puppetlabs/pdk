require 'pdk'

module PDK
  module Validate
    module Tasks
      class TasksValidatorGroup < ValidatorGroup
        def name
          'tasks'
        end

        def validators
          [
            TasksNameValidator,
            TasksMetadataLintValidator,
          ].freeze
        end
      end
    end
  end
end

require 'pdk'

module PDK
  module Validate
    module Tasks
      class TasksNameValidator < InternalRubyValidator
        INVALID_TASK_MSG = 'Invalid task name. Task names must start with a lowercase letter and can only contain lowercase letters, numbers, and underscores.'.freeze

        def name
          'task-name'
        end

        def pattern
          contextual_pattern('tasks/**/*')
        end

        def spinner_text
          'Checking task names (%{pattern}).' % {
            pattern: pattern.join(' '),
          }
        end

        def validate_target(report, target)
          task_name = File.basename(target, File.extname(target))
          if PDK::CLI::Util::OptionValidator.valid_task_name?(task_name)
            report.add_event(
              file:     target,
              source:   name,
              state:    :passed,
              severity: 'ok',
            )
            return 0
          else
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  INVALID_TASK_MSG,
            )
            return 1
          end
        end
      end
    end
  end
end

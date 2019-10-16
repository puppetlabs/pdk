require 'pdk'

module PDK
  module Validate
    class Tasks
      class Name < BaseValidator
        INVALID_TASK_MSG = _(
          'Invalid task name. Task names must start with a lowercase letter ' \
          'and can only contain lowercase letters, numbers, and underscores.',
        )

        def self.name
          'task-name'
        end

        def self.pattern
          'tasks/**/*'
        end

        def self.spinner_text(_targets = [])
          _('Checking task names (%{targets}).') % {
            targets: pattern,
          }
        end

        def self.create_spinner(targets = [], options = {})
          require 'pdk/cli/util'

          return unless PDK::CLI::Util.interactive?
          options = options.merge(PDK::CLI::Util.spinner_opts_for_platform)

          exec_group = options[:exec_group]
          @spinner = if exec_group
                       exec_group.add_spinner(spinner_text(targets), options)
                     else
                       require 'pdk/cli/util/spinner'

                       TTY::Spinner.new("[:spinner] #{spinner_text(targets)}", options)
                     end
          @spinner.auto_spin
        end

        def self.stop_spinner(exit_code)
          if exit_code.zero? && @spinner
            @spinner.success
          elsif @spinner
            @spinner.error
          end
        end

        def self.invoke(report, options = {})
          targets, skipped, invalid = parse_targets(options)

          process_skipped(report, skipped)
          process_invalid(report, invalid)

          return 0 if targets.empty?

          return_val = 0
          create_spinner(targets, options)

          targets.each do |target|
            task_name = File.basename(target, File.extname(target))
            if PDK::CLI::Util::OptionValidator.valid_task_name?(task_name)
              report.add_event(
                file:     target,
                source:   name,
                state:    :passed,
                severity: 'ok',
              )
            else
              report.add_event(
                file:     target,
                source:   name,
                state:    :failure,
                severity: 'error',
                message:  INVALID_TASK_MSG,
              )

              return_val = 1
            end
          end

          stop_spinner(return_val)
          return_val
        end
      end
    end
  end
end

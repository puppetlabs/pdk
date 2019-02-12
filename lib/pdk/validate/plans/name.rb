require 'pdk'
require 'pdk/validate/base_validator'
require 'pdk/util'

module PDK
  module Validate
    class Plans
      class Name < BaseValidator
        INVALID_PLAN_MSG = _(
          'Invalid plan name. Plan names must start with a lowercase letter' \
          'and can only contain lowercase letters, numbers, and underscores.',
        )

        def self.name
          'plan-name'
        end

        def self.pattern
          'plans/**/*'
        end

        def self.spinner_text(_targets = [])
          _('Checking plan names (%{targets}).') % {
            targets: pattern,
          }
        end

        def self.create_spinner(targets = [], options = {})
          return unless PDK::CLI::Util.interactive?
          options = options.merge(PDK::CLI::Util.spinner_opts_for_platform)

          exec_group = options[:exec_group]
          @spinner = if exec_group
                       exec_group.add_spinner(spinner_text(targets), options)
                     else
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
            plan_name = File.basename(target, File.extname(target))
            if PDK::CLI::Util::OptionValidator.valid_plan_name?(plan_name)
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
                message:  INVALID_PLAN_MSG,
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

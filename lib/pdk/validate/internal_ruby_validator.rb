require 'pdk'

module PDK
  module Validate
    # An abstract validator that runs ruby code internal to the PDK e.g. JSON and YAML validation, on a single file.
    # The validator code must run within the PDK Ruby environment as opposed to the bundled Ruby environment for a module.
    #
    # At a a minimum child classes should implment the `name`, `pattern` and `validate_target` methods
    #
    # An example concrete implementation could look like:
    #
    # module PDK
    #   module Validate
    #     module Tasks
    #       class TasksNameValidator < InternalRubyValidator
    #         def name
    #           'task-name'
    #         end
    #
    #         def pattern
    #           'tasks/**/*'
    #         end
    #
    #         def validate_target(report, target)
    #           task_name = File.basename(target, File.extname(target))
    #     ... ruby code ...
    #           success ? 0 : 1
    #         end
    #       end
    #     end
    #   end
    # end
    #
    #
    # @abstract
    # @see PDK::Validate::InvokableValidator
    class InternalRubyValidator < InvokableValidator
      # @see PDK::Validate::Validator.prepare_invoke!
      def prepare_invoke!
        return if @prepared
        super

        # Parse the targets
        @targets, @skipped, @invalid = parse_targets

        nil
      end

      # Invokes the validator to call `validate_target` on each target
      # @see PDK::Validate::Validator.invoke
      def invoke(report)
        prepare_invoke!

        process_skipped(report, @skipped)
        process_invalid(report, @invalid)

        return 0 if @targets.empty?

        return_val = 0

        before_validation

        start_spinner
        @targets.each do |target|
          validation_result = validate_target(report, target)
          if validation_result.nil?
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  "Validation did not return an exit code for #{target}",
            )
            validation_result = 1
          end
          return_val = validation_result if validation_result > return_val
        end

        stop_spinner(return_val.zero?)
        return_val
      end

      # Validates a single target
      # It is the responsibility of this method to populate the report with validation messages
      #
      # @param report [PDK::Report] The report to add the events to
      # @param target [String] The target to validate
      #
      # @return [Integer] The exitcode of the validation. Zero indicates success.  A non-zero code indicates failure
      # @api private
      # @abstract
      def validate_target(report, target); end

      # Tasks to run before validation occurs. This is run once every time `.invoke` is called
      # @api private
      # @abstract
      def before_validation; end
    end
  end
end

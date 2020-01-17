require 'pdk'

module PDK
  module Validate
    # A validator that runs ruby code internal to the PDK e.g. JSON and YAML validation, for a single file
    # @see PDK::Validate::InvokableValidator
    class InternalRubyValidator < InvokableValidator
      def prepare_invoke!
        return if @prepared
        super

        # Parse the targets
        @targets, @skipped, @invalid = parse_targets

        nil
      end

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

      # @api private
      # @abstract
      def validate_target(report, target); end

      # @api private
      # @abstract
      def before_validation; end
    end
  end
end

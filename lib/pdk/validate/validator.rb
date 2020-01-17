require 'pdk'

module PDK
  module Validate
    class Validator
      attr_reader :options

      # Creates a new Validator
      #
      # @param options [Hash] Optional configuration for the Validator
      # @option options :parent_validator [PDK::Validate::Validator] The parent validator for this invocation
      def initialize(options = {})
        @options = options.dup.freeze
        @prepared = false
      end

      # Returns the text used for the spinner to display to the user while invoking
      #
      # @return [String]
      #
      # @abstract
      def spinner_text; end

      # Whether Spinners should be enabled for this validator
      #
      # @return [Boolean]
      #
      # @api private
      # :nocov: .interactive? is tested elsewhere
      def spinners_enabled?
        PDK::CLI::Util.interactive?
      end
      # :nocov:

      # The TTY Spinner for this Validator. Returns nil if spinners are disabled for this validator
      #
      # @return [TTY::Spinner, nil]
      #
      # @api private
      # @abstract
      def spinner; end

      # Start the spinner if it exists
      # @api private
      def start_spinner
        spinner.auto_spin unless spinner.nil?
        nil
      end

      # Stop the spinner if it exists
      # @api private
      def stop_spinner(success)
        return if spinner.nil?
        success ? spinner.success : spinner.error
        nil
      end

      # Name of the Validator
      #
      # @return [String]
      #
      # @abstract
      def name; end

      # Tasks to run prior to invoking
      #
      # @api private
      #
      # @abstract
      def prepare_invoke!
        @prepared = true
      end

      # Invokes the validator and returns the exit code
      #
      # @param report [PDK::Report] Accumulator of events during the invokation of this validator
      #   and potentially child validators
      # @abstract
      def invoke(_report)
        prepare_invoke!
        0
      end
    end
  end
end

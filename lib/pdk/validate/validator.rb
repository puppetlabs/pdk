require 'pdk'

module PDK
  module Validate
    # The base Validator class which all other validators should inherit from.
    # Acutal validator implementation should inherit from other child abstract classes e.g. ValidatorGroup or ExternalCommandValdiator
    # @abstract
    class Validator
      # A hash of options set when the Validator was instantiated
      # @return Hash[Object => Object]
      attr_reader :options

      # Whether the validator is prepared to be invoked.
      # This should only be used for testing
      #
      # @return [Boolean]
      #
      # @api private
      attr_reader :prepared

      # Creates a new Validator
      #
      # @param options [Hash] Optional configuration for the Validator
      # @option options :parent_validator [PDK::Validate::Validator] The parent validator for this validator.
      #   Typically used by ValidatorGroup to create trees of Validators for invocation.
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

      # Once off tasks to run prior to invoking
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
      #   and potential child validators
      # @abstract
      def invoke(_report)
        prepare_invoke!
        0
      end

      # Returns this validator and recursively any child validator instances
      #
      # @return [Array[PDK::Validate::Validator]]
      # @abstract
      def resolve_validator_tree(include_self = true)
        return [self] if child_validators.empty?

        resolved = include_self ? [self] : []
        child_validators.each { |child| resolved.concat(child.resolve_validator_tree(false)) }
        resolved
      end

      # Returns any child validator instances
      #
      # @return [Array[PDK::Validate::Validator]]
      # @abstract
      def child_validators
        []
      end
    end
  end
end

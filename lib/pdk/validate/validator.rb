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

      # The PDK context which the validator will be within.
      # @return [PDK::Context::AbstractContext] or a subclass PDK::Context::AbstractContext
      attr_reader :context

      # Whether the validator is prepared to be invoked.
      # This should only be used for testing
      #
      # @return [Boolean]
      #
      # @api private
      attr_reader :prepared

      # Creates a new Validator
      #
      # @param context [PDK::Context::AbstractContext] Optional context which specifies where the validation will take place.
      #                Passing nil will use a None context (PDK::Context::None)
      # @param options [Hash] Optional configuration for the Validator
      # @option options :parent_validator [PDK::Validate::Validator] The parent validator for this validator.
      #   Typically used by ValidatorGroup to create trees of Validators for invocation.
      def initialize(context = nil, options = {})
        if context.nil?
          @context = PDK::Context::None.new(nil)
        else
          raise ArgumentError, 'Expected PDK::Context::AbstractContext but got \'%{klass}\' for context' % { klass: context.class } unless context.is_a?(PDK::Context::AbstractContext)
          @context = context
        end
        @options = options.dup.freeze
        @prepared = false
      end

      # Whether this Validator can be invoked in this context. By default any Validator can work in any Context
      # @return [Boolean]
      # @abstract
      def valid_in_context?
        true
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
    end
  end
end

require 'pdk'

module PDK
  module Validate
    # The base class which should be used by meta-validators, that is, this group executes other validators
    #
    # At a minimum, the `name` and `validators` methods should be overridden in the child class
    #
    # An example concrete implementation could look like:
    #
    # module PDK
    #   module Validate
    #     module Tasks
    #       class TasksValidatorGroup < ValidatorGroup
    #         def name
    #           'tasks'
    #         end
    #
    #         def validators
    #           [
    #             TasksNameValidator,
    #             TasksMetadataLintValidator,
    #           ].freeze
    #         end
    #       end
    #     end
    #   end
    # end
    #
    # @see PDK::Validate::Validator
    # @abstract
    class ValidatorGroup < Validator
      # @see PDK::Validate::Validator.spinner_text
      def spinner_text
        _('Running %{name} validators ...') % { name: name }
      end

      # @see PDK::Validate::Validator.spinner
      def spinner
        return nil unless spinners_enabled?
        return @spinner unless @spinner.nil?
        require 'pdk/cli/util/spinner'

        @spinner = TTY::Spinner::Multi.new("[:spinner] #{spinner_text}", PDK::CLI::Util.spinner_opts_for_platform)

        # Register the child spinners
        child_validators.each do |instance|
          next if instance.spinner.nil?
          @spinner.register(instance.spinner)
        end

        @spinner
      end

      # Can be overridden by child classes to do their own preparation tasks.
      # Typically this is not required by a meta-validator though.
      #
      # @see PDK::Validate::Validator.prepare_invoke!
      def prepare_invoke!
        return if @prepared
        super

        # Force the spinner to be registered etc.
        spinner

        # Prepare child validators
        child_validators.each { |instance| instance.prepare_invoke! }
        nil
      end

      # A list of Validator classes that this group will run
      # @return Array[Class] An array of Validator classes (or objects that subclass to it) that this group will execute
      # @abstract
      def validators
        []
      end

      # @see PDK::Validate::Validator.invoke
      def invoke(report)
        exit_code = 0

        prepare_invoke!
        start_spinner

        child_validators.each do |instance|
          exit_code = instance.invoke(report)
          break if exit_code != 0
        end

        stop_spinner(exit_code.zero?)

        exit_code
      end

      # The instantiated PDK::Validator::Validator classes from the `validators` array
      # @return Array[PDK::Validator::Validator]
      # @see PDK::Validate::Validator.child_validators
      def child_validators
        @child_validators ||= validators.map { |klass| klass.new(options.merge(parent_validator: self)) }
      end
    end
  end
end

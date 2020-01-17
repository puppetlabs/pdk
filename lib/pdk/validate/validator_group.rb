require 'pdk'

module PDK
  module Validate
    class ValidatorGroup < Validator
      def spinner_text
        _('Running %{name} validators ...') % { name: name }
      end

      def spinner
        return nil unless spinners_enabled?
        return @spinner unless @spinner.nil?
        require 'pdk/cli/util/spinner'

        @spinner = TTY::Spinner::Multi.new("[:spinner] #{spinner_text}", PDK::CLI::Util.spinner_opts_for_platform)

        # Register the child spinners
        validator_instances.each do |instance|
          next if instance.spinner.nil?
          @spinner.register(instance.spinner)
        end

        @spinner
      end

      # @see PDK::Validate::ValidatorBase.prepare_invoke!
      def prepare_invoke!
        return if @prepared
        super

        # Force the spinner to be registered etc.
        spinner

        # Prepare child validators
        validator_instances.each { |instance| instance.prepare_invoke! }
        nil
      end

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

        validator_instances.each do |instance|
          exit_code = instance.invoke(report)
          break if exit_code != 0
        end

        stop_spinner(exit_code.zero?)

        exit_code
      end

      # @return Array[PDK::Validator::Validator] An array of instanitated PDK::Validator::Validator classes from the `validators` array
      # @api private
      def validator_instances
        @validator_instances ||= validators.map { |klass| klass.new(options.merge(parent_validator: self)) }
      end
    end
  end
end

require 'rexml/document'
require 'pathname'

module PDK
  class Report
    class Event
      # @return [String] The path to the file that the event is in reference
      #   to.
      attr_reader :file

      # @return [Integer] The line number in the file that the event is in
      #   reference to.
      attr_reader :line

      # @return [Integer] The column number in the line of the file that the
      #   event is in reference to.
      attr_reader :column

      # @return [String] The name of the source of the event (usually the name
      #   of the validation or testing tool that generated the event).
      attr_reader :source

      # @return [String] A freeform String containing a human readable message
      #   describing the event.
      attr_reader :message

      # @return [String] The severity of the event as reported by the
      #   underlying tool.
      attr_reader :severity

      # @return [String] The name of the test that generated the event.
      attr_reader :test

      # @return [Symbol] The state of the event. :passed, :failure, :error, or
      #   :skipped.
      attr_reader :state

      # Initailises a new PDK::Report::Event object.
      #
      # @param data [Hash{Symbol=>Object}
      # @option data [String] :file (see #file)
      # @option data [Integer] :line (see #line)
      # @option data [Integer] :column (see #column)
      # @option data [String] :source (see #source)
      # @option data [String] :message (see #message)
      # @option data [String] :severity (see #severity)
      # @option data [String] :test (see #test)
      # @option data [Symbol] :state (see #state)
      #
      # @raise [ArgumentError] (see #sanitise_data)
      def initialize(data)
        sanitise_data(data).each do |key, value|
          instance_variable_set("@#{key}", value)
        end
      end

      # Checks if the event is the result of a passing test.
      #
      # @return [Boolean] true if the test passed, otherwise false.
      def pass?
        state == :passed
      end

      # Checks if the event is the result of a test that could not complete due
      # to an error.
      #
      # @return [Boolean] true if the test did not complete, otherwise false.
      def error?
        state == :error
      end

      # Checks if the event is the result of a failing test.
      #
      # @return [Boolean] true if the test failed, otherwise false.
      def failure?
        state == :failure
      end

      # Checks if the event is the result of test that was not run.
      #
      # @return [Boolean] true if the test was skipped, otherwise false.
      def skipped?
        state == :skipped
      end

      # Renders the event in a clang style text format.
      #
      # @return [String] The rendered event.
      def to_text
        location = [file, line, column].compact.join(':')

        [location, severity, message].compact.join(': ')
      end

      # Renders the event as a JUnit XML testcase.
      #
      # @return [REXML::Element] The rendered event.
      def to_junit
        testcase = REXML::Element.new('testcase')
        testcase.attributes['classname'] = [source, test].compact.join('.')
        testcase.attributes['name'] = [file, line, column].compact.join(':')
        testcase.attributes['time'] = 0

        if failure?
          failure = REXML::Element.new('failure')
          failure.attributes['type'] = severity
          failure.attributes['message'] = message
          failure.text = to_text
          testcase.elements << failure
        elsif skipped?
          testcase.add_element('skipped')
        end

        testcase
      end

      private

      # Processes the data hash used to initialise the event, validating and
      # munging the values as necessary.
      #
      # @param data [Hash{Symbol => Object}] (see #initialize)
      #
      # @return [Hash{Symbol => String}] A copy of the data hash passed to the
      #   method with sanitised values.
      #
      # @raise [ArgumentError] (see #sanitise_file)
      # @raise [ArgumentError] (see #sanitise_state)
      # @raise [ArgumentError] (see #sanitise_source)
      def sanitise_data(data)
        result = data.dup
        data.each do |key, value|
          key = key.to_sym unless key.is_a?(Symbol)
          method = "sanitise_#{key}"
          result[key] = send(method, value) if respond_to?(method, true)
        end

        result
      end

      # Munges and validates the file path used to instantiate the event.
      #
      # If the path is an absolute path, it will be rewritten so that it is
      # relative to the module root instead.
      #
      # @param value [String] The path to the file that the event is
      #   describing.
      #
      # @return [String] The path to the file, relative to the module root.
      #
      # @raise [ArgumentError] if the value is nil, an empty String, or not
      #   a String.
      def sanitise_file(value)
        if value.nil? || (value.is_a?(String) && value.empty?)
          raise ArgumentError, _('file not specified')
        end

        unless value.is_a?(String)
          raise ArgumentError, _('file must be a String')
        end

        path = Pathname.new(value)

        if path.absolute?
          module_root = Pathname.new(PDK::Util.module_root)
          path.relative_path_from(module_root).to_path
        else
          path.to_path
        end
      end

      # Munges and validates the state of the event.
      #
      # The valid event states are:
      #   :passed  - The event represents a passing test.
      #   :error   - The event represents a test that could not be completed due
      #              to an unexpected error.
      #   :failure - The event represents a failing test.
      #   :skipped - The event represents a test that was skipped.
      #
      # @param value [Symbol, String] The state of the event. If passed as
      #   a String, it will be turned into a Symbol before validation.
      #
      # @return [Symbol] The sanitised state type.
      #
      # @raise [ArgumentError] if the value is nil, an empty String, or not
      #   a String or Symbol representation of a valid state.
      def sanitise_state(value)
        if value.nil? || (value.is_a?(String) && value.empty?)
          raise ArgumentError, _('state not specified')
        end

        value = value.to_sym if value.is_a?(String)
        unless value.is_a?(Symbol)
          raise ArgumentError, _('state must be a Symbol, not %{type}') % { type: value.class }
        end

        valid_states = [:passed, :error, :failure, :skipped]
        unless valid_states.include?(value)
          raise ArgumentError, _('Invalid state %{state}, valid states are: %{valid}') % {
            state: value.inspect,
            valid: valid_states.map(&:inspect).join(', '),
          }
        end

        value
      end

      # Validates the source of the event.
      #
      # @param value [String, Symbol] The name of the source of the event.
      #
      # @return [String] the value passed to the event, converted to a String
      #   if necessary.
      #
      # @raise [ArgumentError] if the value is nil or an empty String.
      def sanitise_source(value)
        if value.nil? || (value.is_a?(String) && value.empty?)
          raise ArgumentError, _('source not specified')
        end

        value.to_s
      end

      # Munges the line number of the event into an Integer.
      #
      # @param value [Integer, String, Fixnum] The line number.
      #
      # @return [Integer] the provided value, converted into an Integer if
      #   necessary.
      def sanitise_line(value)
        return nil if value.nil?

        valid_types = [String, Integer]
        if RUBY_VERSION.split('.')[0..1].join('.').to_f < 2.4
          valid_types << Fixnum # rubocop:disable Lint/UnifiedInteger
        end

        unless valid_types.include?(value.class)
          raise ArgumentError, _('line must be an Integer or a String representation of an Integer')
        end

        if value.is_a?(String) && value !~ %r{\A[0-9]+\Z}
          raise ArgumentError, _('the line number can only contain the digits 0-9')
        end

        value.to_i
      end

      # Munges the column number of the event into an Integer.
      #
      # @param value [Integer, String, Fixnum] The column number.
      #
      # @return [Integer] the provided value, converted into an Integer if
      #   necessary.
      def sanitise_column(value)
        return nil if value.nil?

        valid_types = [String, Integer]
        if RUBY_VERSION.split('.')[0..1].join('.').to_f < 2.4
          valid_types << Fixnum # rubocop:disable Lint/UnifiedInteger
        end

        unless valid_types.include?(value.class)
          raise ArgumentError, _('column must be an Integer or a String representation of an Integer')
        end

        if value.is_a?(String) && value !~ %r{\A[0-9]+\Z}
          raise ArgumentError, _('the column number can only contain the digits 0-9')
        end

        value.to_i
      end
    end
  end
end

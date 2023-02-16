require 'pdk'

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

      # @return [Array] Array of full stack trace lines associated with event
      attr_reader :trace

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
      # @option data [Array] :trace (see #trace)
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
      # This includes pending tests (that are run but have an expected failure result).
      #
      # @return [Boolean] true if the test was skipped, otherwise false.
      def skipped?
        state == :skipped
      end

      # Checks if the event stores the result of an rspec-puppet coverage
      # check.
      #
      # Due to the implementation details of this check, the `file` value for
      # this event will always point to the coverage.rb file in rspec-puppet,
      # making it easy to filter out.
      #
      # @return [Boolean] true if the event contains rspec-puppet coverage
      #   results.
      def rspec_puppet_coverage?
        @rspec_puppet_coverage_pattern ||= File.join('**', 'lib', 'rspec-puppet', 'coverage.rb')
        source == 'rspec' && PDK::Util::Filesystem.fnmatch?(@rspec_puppet_coverage_pattern, PDK::Util::Filesystem.expand_path(file))
      end

      # Renders the event in a clang style text format.
      #
      # @return [String] The rendered event.
      def to_text
        return message if rspec_puppet_coverage?

        location = [file, line, column].compact.join(':')
        location = nil if location.empty?

        # TODO: maybe add trace
        if source == 'rspec'
          header = [severity, source, location, message].compact.join(': ')
          result = [header, "  #{test}"]
          context = context_lines
          unless context.nil?
            result << '  Failure/Error:'
            result.concat(context)
            result << "\n"
          end

          result.compact.join("\n")
        else
          output = ['pdk']
          output << "(#{severity.upcase}):" unless severity.nil?
          output << "#{source}:" unless source.nil?
          output << message unless message.nil?
          output << "(#{location})" unless location.nil?

          output.join(' ')
        end
      end

      # Renders the event as a JUnit XML testcase.
      #
      # @return [REXML::Element] The rendered event.
      def to_junit
        require 'rexml/document'

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
          raise ArgumentError, 'File not specified.'
        end

        unless value.is_a?(String)
          raise ArgumentError, 'File must be a String.'
        end

        require 'pathname'
        require 'pdk/util'

        path = Pathname.new(value)

        if path.absolute?
          module_root = Pathname.new(PDK::Util.module_root)
          path = path.relative_path_from(module_root).to_path
          path << '/' if path == '.'
          path
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
          raise ArgumentError, 'State not specified.'
        end

        value = value.to_sym if value.is_a?(String)
        unless value.is_a?(Symbol)
          raise ArgumentError, 'State must be a Symbol, not %{type}' % { type: value.class }
        end

        valid_states = [:passed, :error, :failure, :skipped]
        unless valid_states.include?(value)
          raise ArgumentError, 'Invalid state %{state}. Valid states are: %{valid}.' % {
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
          raise ArgumentError, 'Source not specified.'
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
        return if value.nil?

        valid_types = [String, Integer]
        if RUBY_VERSION.split('.')[0..1].join('.').to_f < 2.4
          valid_types << Fixnum # rubocop:disable Lint/UnifiedInteger
        end

        unless valid_types.include?(value.class)
          raise ArgumentError, 'Line must be an Integer or a String representation of an Integer.'
        end

        if value.is_a?(String) && value !~ %r{\A[0-9]+\Z}
          raise ArgumentError, 'The line number can contain only the digits 0-9.'
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
        return if value.nil?

        valid_types = [String, Integer]
        if RUBY_VERSION.split('.')[0..1].join('.').to_f < 2.4
          valid_types << Fixnum # rubocop:disable Lint/UnifiedInteger
        end

        unless valid_types.include?(value.class)
          raise ArgumentError, 'Column must be an Integer or a String representation of an Integer.'
        end

        if value.is_a?(String) && value !~ %r{\A[0-9]+\Z}
          raise ArgumentError, 'The column number can contain only the digits 0-9.'
        end

        value.to_i
      end

      # Cleans up provided stack trace by removing entries that are inside gems
      # or the rspec binstub.
      #
      # @param value [Array] Array of stack trace lines
      #
      # @return [Array] Array of stack trace lines with less relevant lines excluded
      def sanitise_trace(value)
        return if value.nil?

        valid_types = [Array]

        unless valid_types.include?(value.class)
          raise ArgumentError, 'Trace must be an Array of stack trace lines.'
        end

        # Drop any stacktrace lines that include '/gems/' in the path or
        # are the original rspec binstub lines
        value.reject do |line|
          (line =~ %r{/gems/}) || (line =~ %r{bin/rspec:})
        end
      end

      # Extract contextual information for the event from the file that it
      # references.
      #
      # @param max_num_lines [Integer] The maximum number of lines to return.
      #
      # @return [Array] Array of lines from the file, centred on the line
      #   number of the event.
      def context_lines(max_num_lines = 5)
        return if file.nil? || line.nil?

        file_path = [file, File.join(PDK::Util.module_root, file)].find do |path|
          PDK::Util::Filesystem.file?(path)
        end

        return if file_path.nil?

        file_content = PDK::Util::Filesystem.read_file(file_path).split("\n")
        delta = (max_num_lines - 1) / 2
        min = [0, (line - 1) - delta].max
        max = [(line - 1) + delta, file_content.length].min

        file_content[min..max].map { |r| "  #{r}" }
      end
    end
  end
end

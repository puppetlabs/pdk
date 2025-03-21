require 'pdk'

module PDK
  class Report
    autoload :Event, 'pdk/report/event'

    # @return [Array<String>] the list of supported report formats.
    def self.formats
      @formats ||= ['junit', 'text'].freeze
    end

    # @return [Symbol] the method name of the default report format.
    def self.default_format
      :write_text
    end

    # @return [#write] the default target to write the report to.
    def self.default_target
      $stdout
    end

    # Memoised access to the report event storage hash.
    #
    # The keys of the Hash are the source names of the Events (see
    # PDK::Report::Event#source).
    #
    # @example accessing events from the puppet-lint validator
    #   report = PDK::Report.new
    #   report.events['puppet-lint']
    #
    # @return [Hash{String=>Array<PDK::Report::Event>}] the events stored in
    #   the repuort.
    def events
      @events ||= {}
    end

    # Create a new PDK::Report::Event from a hash of values and add it to the
    # report.
    #
    # @param data [Hash] (see PDK::Report::Event#initialize)
    def add_event(data)
      (events[data[:source]] ||= []) << PDK::Report::Event.new(data)
    end

    # Renders the report as a JUnit XML document.
    #
    # @param target [#write] an IO object that the report will be written to.
    #   Defaults to PDK::Report.default_target.
    def write_junit(target = self.class.default_target)
      require 'rexml/document'
      require 'time'
      require 'socket'

      document = REXML::Document.new
      document << REXML::XMLDecl.new
      testsuites = REXML::Element.new('testsuites')

      id = 0
      events.each do |testsuite_name, testcases|
        testsuite = REXML::Element.new('testsuite')
        testsuite.attributes['name'] = testsuite_name
        testsuite.attributes['tests'] = testcases.length
        testsuite.attributes['errors'] = testcases.count(&:error?)
        testsuite.attributes['failures'] = testcases.count(&:failure?)
        testsuite.attributes['skipped'] = testcases.count(&:skipped?)
        testsuite.attributes['time'] = 0
        testsuite.attributes['timestamp'] = Time.now.strftime('%Y-%m-%dT%H:%M:%S')
        testsuite.attributes['hostname'] = Socket.gethostname
        testsuite.attributes['id'] = id
        testsuite.attributes['package'] = testsuite_name
        testsuite.add_element('properties')
        testcases.each { |r| testsuite.elements << r.to_junit }
        testsuite.add_element('system-out')
        testsuite.add_element('system-err')

        testsuites.elements << testsuite
        id += 1
      end

      document.elements << testsuites
      report = ''
      document.write(report, 2)

      if target.is_a?(String)
        PDK::Util::Filesystem.write_file(target, report)
      else
        target << report
      end
    end

    # Renders the report as plain text.
    #
    # This report is designed for interactive use by a human and so excludes
    # all passing events in order to be consise.
    #
    # @param target [String, IO] The IO target to write the report to.
    #   If a String is provided, the report will be written to a file with the given path.
    #   If an IO object is provided, the report will be written to the IO object.
    #   If no target is provided, the default target PDK::Report.default_target will be used.
    #
    # @return [void]
    def write_text(target = self.class.default_target)
      coverage_report = nil
      report = []

      events.each_value do |tool_events|
        tool_events.each do |event|
          if event.rspec_puppet_coverage?
            coverage_report = event.to_text
          else
            report << event.to_text unless event.pass? || event.skipped?
          end
        end
      end

      report << "\n#{coverage_report}" if coverage_report

      if target.is_a?(String)
        PDK::Util::Filesystem.write_file(target, report.join("\n"))
      elsif !report.empty?
        target << report.join("\n") << "\n"
      end
    end
  end
end

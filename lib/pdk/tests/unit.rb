require 'pdk'

module PDK
  module Test
    class Unit
      def self.cmd(tests, opts = {})
        rake_args = opts[:parallel] ? 'parallel_spec_standalone' : 'spec_standalone'
        rake_args += "[#{tests}]" unless tests.nil? || tests.empty?
        rake_args
      end

      def self.rake_bin
        require 'pdk/util'

        @rake ||= File.join(PDK::Util.module_root, 'bin', 'rake')
      end

      def self.cmd_with_args(task)
        require 'pdk/util/ruby_version'

        argv = [rake_bin, task]
        argv.unshift(File.join(PDK::Util::RubyVersion.bin_path, 'ruby.exe')) if Gem.win_platform?
        argv
      end

      def self.rake(task, spinner_text, environment = {})
        require 'pdk/cli/exec/command'

        command = PDK::CLI::Exec::Command.new(*cmd_with_args(task)).tap do |c|
          c.context = :module
          c.add_spinner(spinner_text) if spinner_text
          c.environment = environment
        end

        command.execute!
      end

      def self.interactive_rake(task, environment)
        require 'pdk/cli/exec/interactive_command'

        command = PDK::CLI::Exec::InteractiveCommand.new(*cmd_with_args(task)).tap do |c|
          c.context = :module
          c.environment = environment
        end

        command.execute!
      end

      def self.parallel_with_no_tests?(ran_in_parallel, json_result, result)
        ran_in_parallel && json_result.empty? &&
          ((!result[:exit_code].zero? && result[:stderr].strip =~ %r{Pass files or folders to run$}) ||
           result[:stderr].strip =~ %r{No files for parallel_spec to run against$})
      end

      def self.print_failure(result, exception)
        $stderr.puts ''
        result[:stdout].each_line { |line| $stderr.puts line.rstrip } unless result[:stdout].nil?
        result[:stderr].each_line { |line| $stderr.puts line.rstrip } unless result[:stderr].nil?
        $stderr.puts ''
        raise PDK::CLI::FatalError, exception
      end

      def self.tear_down
        result = rake('spec_clean', 'Cleaning up after running unit tests.')

        return if result[:exit_code].zero?

        PDK.logger.error('The spec_clean rake task failed with the following error(s):')
        print_failure(result, 'Failed to clean up after running unit tests')
      end

      def self.setup
        result = rake('spec_prep', 'Preparing to run the unit tests.')

        return if result[:exit_code].zero?

        tear_down

        PDK.logger.error('The spec_prep rake task failed with the following error(s):')
        print_failure(result, 'Failed to prepare to run the unit tests.')
      end

      def self.invoke(report, options = {})
        require 'pdk/util'
        require 'pdk/util/bundler'

        PDK::Util::Bundler.ensure_binstubs!('rake', 'rspec-core')

        setup

        tests = options[:tests]
        # Due to how rake handles paths in the command line options, any backslashed path (Windows platforms) needs to be converted
        # to forward slash. We can't use File.expand_path as the files aren't guaranteed to be on-disk
        #
        # Ref - https://github.com/puppetlabs/pdk/issues/828
        tests = tests.tr('\\', '/') unless tests.nil?

        environment = { 'CI_SPEC_OPTIONS' => '--format j' }
        environment['PUPPET_GEM_VERSION'] = options[:puppet] if options[:puppet]
        spinner_msg = options[:parallel] ? 'Running unit tests in parallel.' : 'Running unit tests.'

        if options[:interactive]
          environment['CI_SPEC_OPTIONS'] = if options[:verbose]
                                             '--format documentation'
                                           else
                                             '--format progress'
                                           end
          result = interactive_rake(cmd(tests, options), environment)
          return result[:exit_code]
        end

        result = rake(cmd(tests, options), spinner_msg, environment)

        json_result = if options[:parallel]
                        PDK::Util.find_all_json_in(result[:stdout])
                      else
                        PDK::Util.find_first_json_in(result[:stdout])
                      end

        if parallel_with_no_tests?(options[:parallel], json_result, result)
          json_result = [{ 'messages' => ['No examples found.'] }]
          result[:exit_code] = 0
        end

        raise PDK::CLI::FatalError, 'Unit test output did not contain a valid JSON result: %{output}' % { output: result[:stdout] } if json_result.nil? || json_result.empty?

        json_result = merge_json_results(json_result) if options[:parallel]

        parse_output(report, json_result, result[:duration])

        result[:exit_code]
      ensure
        tear_down if options[:'clean-fixtures']
      end

      def self.parse_output(report, json_data, duration)
        # Output messages to stderr.
        json_data['messages'] && json_data['messages'].each { |msg| $stderr.puts msg }

        example_results = {
          # Only possibilities are passed, failed, pending:
          # https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/example.rb#L548
          'passed' => [],
          'failed' => [],
          'pending' => [],
        }

        json_data['examples'] && json_data['examples'].each do |ex|
          example_results[ex['status']] << ex if example_results.key?(ex['status'])
        end

        example_results.each do |result, examples|
          # Translate rspec example results to JUnit XML testcase results
          state = case result
                  when 'passed' then :passed
                  when 'failed' then :failure
                  when 'pending' then :skipped
                  end

          examples.each do |ex|
            report.add_event(
              source: 'rspec',
              state: state,
              file: ex['file_path'],
              line: ex['line_number'],
              test: ex['full_description'],
              severity: ex['status'],
              message: ex['pending_message'] || (ex['exception'] && ex['exception']['message']) || nil,
              trace: (ex['exception'] && ex['exception']['backtrace']) || nil,
            )
          end
        end

        return unless json_data['summary']

        # TODO: standardize summary output
        $stderr.puts '  ' << 'Evaluated %{total} tests in %{duration} seconds: %{failures} failures, %{pending} pending.' % {
          total: json_data['summary']['example_count'],
          duration: duration,
          failures: json_data['summary']['failure_count'],
          pending: json_data['summary']['pending_count'],
        }
      end

      def self.merge_json_results(json_data)
        require 'set'

        merged_json_result = {}

        # Merge messages
        message_set = Set.new
        json_data.each do |json|
          next unless json['messages']
          message_set |= json['messages']
        end
        merged_json_result['messages'] = message_set.to_a

        # Merge examples
        all_examples = []
        json_data.each do |json|
          next unless json['examples']
          all_examples.concat json['examples']
        end
        merged_json_result['examples'] = all_examples

        # Merge summaries
        summary_hash = {
          'example_count' => 0,
          'failure_count' => 0,
          'pending_count' => 0,
        }
        json_data.each do |json|
          next unless json['summary']
          summary_hash['example_count'] += json['summary']['example_count']
          summary_hash['failure_count'] += json['summary']['failure_count']
          summary_hash['pending_count'] += json['summary']['pending_count']
        end
        merged_json_result['summary'] = summary_hash

        merged_json_result
      end

      # @return array of { :id, :full_description }
      def self.list(options = {})
        require 'pdk/util'
        require 'pdk/util/bundler'

        PDK::Util::Bundler.ensure_binstubs!('rake')

        environment = {}
        environment['PUPPET_GEM_VERSION'] = options[:puppet] if options[:puppet]

        output = rake('spec_list_json', 'Finding unit tests.', environment)

        rspec_json = PDK::Util.find_first_json_in(output[:stdout])
        raise PDK::CLI::FatalError, 'Failed to find valid JSON in output from rspec: %{output}' % { output: output[:stdout] } unless rspec_json
        if rspec_json['examples'].empty?
          rspec_message = rspec_json['messages'][0]
          return [] if rspec_message == 'No examples found.'

          raise PDK::CLI::FatalError, 'Unable to enumerate examples. rspec reported: %{message}' % { message: rspec_message }
        else
          examples = []
          rspec_json['examples'].each do |example|
            examples << { file_path: example['file_path'], id: example['id'], full_description: example['full_description'] }
          end
          examples
        end
      end
    end
  end
end

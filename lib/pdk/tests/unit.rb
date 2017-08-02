require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util/bundler'
require 'json'

module PDK
  module Test
    class Unit
      def self.cmd(_tests, opts = {})
        # TODO: test selection
        rake_task = opts.key?(:parallel) ? 'parallel_spec' : 'spec'
        [File.join(PDK::Util.module_root, 'bin', 'rake'), rake_task]
      end

      def self.parallel_with_no_tests?(ran_in_parallel, json_result, result)
        ran_in_parallel && json_result.empty? &&
          !result[:exit_code].zero? &&
          result[:stderr].strip =~ %r{Pass files or folders to run$}
      end

      def self.invoke(report, options = {})
        PDK::Util::Bundler.ensure_bundle!
        PDK::Util::Bundler.ensure_binstubs!('rake')

        tests = options.fetch(:tests)

        cmd_argv = cmd(tests, options)
        cmd_argv.unshift('ruby') if Gem.win_platform?

        command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
          c.context = :module
          spinner_msg = options.key?(:parallel) ? _('Running unit tests in parallel') : _('Running unit tests')
          c.add_spinner(spinner_msg)
          c.environment['CI_SPEC_OPTIONS'] = '--format j'
        end

        PDK.logger.debug(_('Running %{cmd}') % { cmd: command.argv.join(' ') })

        result = command.execute!

        # TODO: cleanup rspec and/or beaker output
        # Iterate through possible JSON documents until we find one that is valid.
        json_result = nil
        json_result = [] if options.key?(:parallel)

        result[:stdout].scan(%r{\{(?:[^{}]|(?:\g<0>))*\}}x) do |str|
          begin
            if options.key?(:parallel)
              json_result.push(JSON.parse(str))
            else
              json_result = JSON.parse(str)
              break
            end
          rescue JSON::ParserError
            next
          end
        end

        if parallel_with_no_tests?(options.key?(:parallel), json_result, result)
          json_result = [{ 'messages' => ['No examples found.'] }]
          result[:exit_code] = 0
        end

        raise PDK::CLI::FatalError, _('Unit test output did not contain a valid JSON result: %{output}') % { output: result[:stdout] } if json_result.nil? || json_result.empty?

        json_result = merge_json_results(json_result, result[:duration]) if options.key?(:parallel)

        parse_output(report, json_result)

        result[:exit_code]
      end

      def self.parse_output(report, json_data)
        # Output messages to stderr.
        json_data['messages'] && json_data['messages'].each { |msg| $stderr.puts msg }

        example_results = {
          # Only possibilities are passed, failed, pending:
          # https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/example.rb#L548
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
        $stderr.puts '  ' << _('Evaluated %{total} tests in %{duration} seconds: %{failures} failures, %{pending} pending') % {
          total: json_data['summary']['example_count'],
          duration: json_data['summary']['duration'],
          failures: json_data['summary']['failure_count'],
          pending: json_data['summary']['pending_count'],
        }
      end

      def self.merge_json_results(json_data, duration)
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
          'duration'      => duration,
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
      def self.list
        PDK::Util::Bundler.ensure_bundle!
        PDK::Util::Bundler.ensure_binstubs!('rspec-core')

        command_argv = [File.join(PDK::Util.module_root, 'bin', 'rspec'), '--dry-run', '--format', 'json']
        command_argv.unshift('ruby') if Gem.win_platform?
        list_command = PDK::CLI::Exec::Command.new(*command_argv)
        list_command.context = :module
        output = list_command.execute!

        rspec_json_output = JSON.parse(output[:stdout])
        if rspec_json_output['examples'].empty?
          rspec_message = rspec_json_output['messages'][0]
          return [] if rspec_message == 'No examples found.'

          raise PDK::CLI::FatalError, _('Unable to enumerate examples. rspec reported: %{message}' % { message: rspec_message })
        else
          examples = []
          rspec_json_output['examples'].each do |example|
            examples << { id: example['id'], full_description: example['full_description'] }
          end
          examples
        end
      rescue JSON::ParserError => e
        raise PDK::CLI::FatalError, _('Failed to parse output from rspec: %{message}' % { message: e.message })
      end
    end
  end
end

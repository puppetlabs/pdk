require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util/bundler'

module PDK
  module Test
    class Unit
      def self.cmd(_tests)
        # TODO: test selection
        [File.join(PDK::Util.module_root, 'bin', 'rake'), 'spec']
      end

      def self.invoke(report, options = {})
        PDK::Util::Bundler.ensure_bundle!
        PDK::Util::Bundler.ensure_binstubs!('rake')

        tests = options.fetch(:tests)

        cmd_argv = cmd(tests)
        cmd_argv.unshift('ruby') if Gem.win_platform?

        command = PDK::CLI::Exec::Command.new(*cmd_argv).tap do |c|
          c.context = :module
          c.add_spinner('Running unit tests')
          c.environment['CI_SPEC_OPTIONS'] = '--format j'
        end

        PDK.logger.debug(_('Running %{cmd}') % { cmd: command.argv.join(' ') })

        result = command.execute!

        # TODO: cleanup rspec and/or beaker output
        # Iterate through possible JSON documents until we find one that is valid.
        json_result = nil

        result[:stdout].scan(%r{\{(?:[^{}]|(?:\g<0>))*\}}x) do |str|
          begin
            json_result = JSON.parse(str)
            break
          rescue JSON::ParserError
            next
          end
        end

        raise PDK::CLI::FatalError, _('Unit test output did not contain a valid JSON result: %{output}') % { output: result[:stdout] } unless json_result

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
    end
  end
end

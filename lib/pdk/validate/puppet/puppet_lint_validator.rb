require 'pdk'

module PDK
  module Validate
    module Puppet
      class PuppetLintValidator < ExternalCommandValidator
        def name
          'puppet-lint'
        end

        def cmd
          'puppet-lint'
        end

        def pattern
          contextual_pattern('**/*.pp')
        end

        def spinner_text_for_targets(_targets)
          'Checking Puppet manifest style (%{pattern}).' % { pattern: pattern.join(' ') }
        end

        def parse_options(targets)
          cmd_options = ['--json', '--relative']

          cmd_options << '--fix' if options[:auto_correct]

          cmd_options.concat(targets)
        end

        def parse_output(report, result, targets)
          begin
            json_data = JSON.parse(result[:stdout]).flatten
          rescue JSON::ParserError
            raise PDK::Validate::ParseOutputError, result[:stdout]
          end

          # puppet-lint does not include files without problems in its JSON
          # output, so we need to go through the list of targets and add passing
          # events to the report for any target not listed in the JSON output.
          targets.reject { |target| json_data.any? { |j| j['path'] == target } }.each do |target|
            report.add_event(
              file:     target,
              source:   name,
              severity: 'ok',
              state:    :passed,
            )
          end

          json_data.each do |offense|
            report.add_event(
              file:     offense['path'],
              source:   name,
              line:     offense['line'],
              column:   offense['column'],
              message:  offense['message'],
              test:     offense['check'],
              severity: (offense['kind'] == 'fixed') ? 'corrected' : offense['kind'],
              state:    :failure,
            )
          end
        end
      end
    end
  end
end

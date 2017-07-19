require 'pdk'
require 'pdk/util'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetLint < BaseValidator
      def self.name
        'puppet-lint'
      end

      def self.cmd
        'puppet-lint'
      end

      def self.pattern
        '**/*.pp'
      end

      def self.spinner_text(_targets = nil)
        _('Checking Puppet manifest style')
      end

      def self.parse_options(options, targets)
        cmd_options = ['--json']

        cmd_options << '--fix' if options[:auto_correct]

        cmd_options.concat(targets)
      end

      def self.parse_output(report, result, targets)
        begin
          json_data = JSON.parse(result[:stdout]).flatten
        rescue JSON::ParserError
          json_data = []
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

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
        File.join(PDK::Util.module_root, 'bin', 'puppet-lint')
      end

      def self.pattern
        '**/*.pp'
      end

      def self.spinner_text
        _('Checking Puppet manifest style')
      end

      def self.parse_options(_options, targets)
        cmd_options = ['--json']

        cmd_options.concat(targets)
      end

      def self.parse_output(report, json_data)
        json_data.each do |offense|
          report.add_event(
            file:     offense['path'],
            source:   'puppet-lint',
            line:     offense['line'],
            column:   offense['column'],
            message:  offense['message'],
            test:     offense['check'],
            severity: offense['kind'],
            state:    :failure,
          )
        end
      end
    end
  end
end

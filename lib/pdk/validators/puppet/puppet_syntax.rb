require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'

module PDK
  module Validate
    class PuppetSyntax < BaseValidator
      def self.name
        'puppet-syntax'
      end

      def self.cmd
        'puppet'
      end

      def self.pattern
        '**/**.pp'
      end

      def self.spinner_text
        _('Checking Puppet manifest syntax')
      end

      def self.parse_options(_options, targets)
        %w[parser validate].concat(targets)
      end

      def self.parse_output(report, result, _targets)
        # Due to PUP-7504, we will have to programmatically construct the json
        # object from the text output for now.
        output = result[:stderr].split("\n")

        output.each do |offense|
          sanitize_console_output(offense)
          message, _at, location = offense.rpartition('at')

          # Parse the offense type and msg
          severity = message.split(':').first

          # Parse the offense location info
          file, line, column = location.split(':') unless location.nil?

          inputs = {
            source:  name,
            message: message.strip,
            file:    file.strip,
            state:  'failure',
          }
          inputs[:severity] = severity.strip unless severity.nil?
          inputs[:line] = line.strip unless line.nil?
          inputs[:column] = column.strip unless column.nil?
          report.add_event(inputs)
        end
      end

      def self.sanitize_console_output(line)
        line.gsub!(%r{\e\[([;\d]+)?m}, '')
      end
    end
  end
end

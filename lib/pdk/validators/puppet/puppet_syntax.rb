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

      def self.spinner_text(_targets = nil)
        _('Checking Puppet manifest syntax')
      end

      def self.parse_options(_options, targets)
        %w[parser validate].concat(targets)
      end

      def self.parse_output(report, result, targets)
        # Due to PUP-7504, we will have to programmatically construct the json
        # object from the text output for now.
        output = result[:stderr].split("\n")

        results_data = []
        output.each do |offense|
          sanitize_console_output(offense)
          message, _at, location_raw = offense.partition(' at ')

          # Parse the offense type and msg
          severity, _colon, message = message.rpartition(': ')

          # Parse the offense location info
          location = location_raw.strip.match(%r{\A(?<file>.+):(?<line>\d+):(?<column>\d+)\Z}) unless location_raw.nil?

          attributes = {
            source:  name,
            message: message.strip,
            state:  :failure,
          }
          attributes[:severity] = severity.strip unless severity.nil?

          unless location.nil?
            attributes[:file] = location[:file]
            attributes[:line] = location[:line]
            attributes[:column] = location[:column]
          end

          results_data << attributes
        end

        # puppet parser validate does not include files without problems in its
        # output, so we need to go through the list of targets and add passing
        # events to the report for any target not listed in the output.
        targets.reject { |target| results_data.any? { |j| j[:file] == target } }.each do |target|
          report.add_event(
            file:     target,
            source:   name,
            severity: :ok,
            state:    :passed,
          )
        end

        results_data.each do |offense|
          report.add_event(offense)
        end
      end

      def self.sanitize_console_output(line)
        line.gsub!(%r{\e\[([;\d]+)?m}, '')
      end
    end
  end
end

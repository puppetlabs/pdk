# frozen_string_literal: true

require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validate/base_validator'

module PDK
  module Validate
    class PuppetSyntax < BaseValidator
      # In Puppet >= 5.3.4, the error context formatting was changed to facilitate localization
      ERROR_CONTEXT = %r{(?:file:\s(?<file>.+?)|line:\s(?<line>.+?)|column:\s(?<column>.+?))}
      # In Puppet < 5.3.3, the error context was formatted in these variations:
      #   - "at file_path:line_num:col_num"
      #   - "at file_path:line_num"
      #   - "at line line_num"
      #   - "in file_path"
      ERROR_CONTEXT_LEGACY = %r{(?:at\sline\s(?<line>\d+)|at\s(?<file>.+?):(?<line>\d+):(?<column>\d+)|at\s(?<file>.+?):(?<line>\d+)|in\s(?<file>.+?))}

      PUPPET_SYNTAX_PATTERN = %r{^
        (?<severity>.+?):\s
        (?<message>.+?)
        (?:
          \s\(#{ERROR_CONTEXT}(,\s#{ERROR_CONTEXT})*\)| # attempt to match the new localisation friendly location
          \s#{ERROR_CONTEXT_LEGACY}| # attempt to match the old " at file:line:column" location
          $                                               # handle cases where the output has no location
        )
      $}x

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
        _('Checking Puppet manifest syntax (%{pattern}).') % { pattern: pattern }
      end

      def self.parse_options(_options, targets)
        ['parser', 'validate', '--config', null_file].concat(targets)
      end

      def self.null_file
        Gem.win_platform? ? 'NUL' : '/dev/null'
      end

      def self.parse_output(report, result, targets)
        # Due to PUP-7504, we will have to programmatically construct the json
        # object from the text output for now.
        output = result[:stderr].split("\n").reject { |entry| entry.empty? }

        results_data = []
        output.each do |offense|
          offense_data = parse_offense(offense)
          results_data << offense_data
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

      def self.parse_offense(offense)
        sanitize_console_output(offense)

        offense_data = {
          source:  name,
          state:  :failure,
        }

        attributes = offense.match(PUPPET_SYNTAX_PATTERN)

        attributes.names.each do |name|
          offense_data[name.to_sym] = attributes[name] unless attributes[name].nil?
        end

        offense_data
      end

      def self.sanitize_console_output(line)
        line.gsub!(%r{\e\[([;\d]+)?m}, '')
      end
    end
  end
end

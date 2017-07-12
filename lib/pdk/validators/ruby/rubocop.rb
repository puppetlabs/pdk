require 'pdk'
require 'pdk/cli/exec'
require 'pdk/util'
require 'pdk/util/bundler'
require 'pdk/validators/base_validator'
require 'pdk/validators/ruby_validator'

module PDK
  module Validate
    class Rubocop < BaseValidator
      def self.name
        'rubocop'
      end

      def self.cmd
        'rubocop'
      end

      def self.spinner_text(_targets = nil)
        _('Checking Ruby code style')
      end

      def self.parse_options(options, targets)
        cmd_options = ['--format', 'json']

        if options[:auto_correct]
          cmd_options << '--auto-correct'
        end

        cmd_options.concat(targets)
      end

      def self.parse_output(report, result, _targets)
        return if result[:stdout].empty?

        begin
          json_data = JSON.parse(result[:stdout])
        rescue JSON::ParserError
          json_data = {}
        end

        return unless json_data.key?('files')

        json_data['files'].each do |file_info|
          next unless file_info.key?('offenses')
          result = {
            file: file_info['path'],
            source: 'rubocop',
          }

          if file_info['offenses'].empty?
            report.add_event(result.merge(state: :passed, severity: :ok))
          else
            file_info['offenses'].each do |offense|
              report.add_event(
                result.merge(
                  line:     offense['location']['line'],
                  column:   offense['location']['column'],
                  message:  offense['message'],
                  severity: (offense['corrected']) ? 'corrected' : offense['severity'],
                  test:     offense['cop_name'],
                  state:    :failure,
                ),
              )
            end
          end
        end
      end
    end
  end
end

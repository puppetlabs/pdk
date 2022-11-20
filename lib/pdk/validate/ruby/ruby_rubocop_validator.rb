require 'pdk'

module PDK
  module Validate
    module Ruby
      class RubyRubocopValidator < ExternalCommandValidator
        def allow_empty_targets?
          true
        end

        def name
          'rubocop'
        end

        def cmd
          'rubocop'
        end

        def pattern
          if context.is_a?(PDK::Context::ControlRepo)
            ['Puppetfile', '**/**.rb']
          else
            '**/**.rb'
          end
        end

        def spinner_text_for_targets(_targets)
          'Checking Ruby code style (%{pattern}).' % { pattern: pattern }
        end

        def parse_options(targets)
          cmd_options = ['--format', 'json']

          if options[:auto_correct]
            cmd_options << '--auto-correct'
          end

          cmd_options.concat(targets)
        end

        def parse_output(report, result, _targets)
          return if result[:stdout].empty?

          begin
            json_data = JSON.parse(result[:stdout])
          rescue JSON::ParserError
            raise PDK::Validate::ParseOutputError, result[:stdout]
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
                    severity: offense['corrected'] ? 'corrected' : offense['severity'],
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
end

require 'pdk'

module PDK
  module Validate
    module Metadata
      class MetadataJSONLintValidator < ExternalCommandValidator
        # Validate each metadata file separately, as metadata-json-lint does not
        # support multiple targets.
        def invoke_style
          :per_target
        end

        def name
          'metadata-json-lint'
        end

        def cmd
          'metadata-json-lint'
        end

        def spinner_text_for_targets(targets)
          'Checking module metadata style (%{targets}).' % {
            targets: PDK::Util.targets_relative_to_pwd(targets.flatten).join(' '),
          }
        end

        def pattern
          contextual_pattern('metadata.json')
        end

        def parse_options(targets)
          cmd_options = ['--format', 'json']
          cmd_options << '--strict-dependencies'

          cmd_options.concat(targets)
        end

        def parse_output(report, result, targets)
          raise ArgumentError, 'More than 1 target provided to PDK::Validate::MetadataJSONLintValidator.' if targets.count > 1

          if result[:stdout].strip.empty?
            # metadata-json-lint will print nothing if there are no problems with
            # the file being linted. This should be handled separately to
            # metadata-json-lint generating output that can not be parsed as JSON
            # (unhandled exception in metadata-json-lint).
            json_data = {}
          else
            begin
              json_data = JSON.parse(result[:stdout])
            rescue JSON::ParserError
              raise PDK::Validate::ParseOutputError, result[:stdout]
            end
          end

          if json_data.empty?
            report.add_event(
              file:     targets.first,
              source:   name,
              state:    :passed,
              severity: :ok,
            )
          else
            json_data.delete('result')
            json_data.keys.each do |type|
              json_data[type].each do |offense|
                # metadata-json-lint groups the offenses by type, so the type ends
                # up being `warnings` or `errors`. We want to convert that to the
                # singular noun for the event.
                event_type = type[%r{\A(.+?)s?\Z}, 1]

                report.add_event(
                  file:     targets.first,
                  source:   name,
                  message:  offense['msg'],
                  test:     offense['check'],
                  severity: event_type,
                  state:    :failure,
                )
              end
            end
          end
        end
      end
    end
  end
end

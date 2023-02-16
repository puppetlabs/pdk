require 'pdk'

module PDK
  module Validate
    module Tasks
      class TasksMetadataLintValidator < InternalRubyValidator
        FORGE_SCHEMA_URL = 'https://forgeapi.puppet.com/schemas/task.json'.freeze

        def name
          'task-metadata-lint'
        end

        def pattern
          contextual_pattern('tasks/*.json')
        end

        def spinner_text
          'Checking task metadata style (%{pattern}).' % {
            pattern: pattern.join(' '),
          }
        end

        def schema_file
          require 'pdk/util/vendored_file'

          schema = PDK::Util::VendoredFile.new('task.json', FORGE_SCHEMA_URL).read

          JSON.parse(schema)
        rescue PDK::Util::VendoredFile::DownloadError => e
          raise PDK::CLI::FatalError, e.message
        rescue JSON::ParserError
          raise PDK::CLI::FatalError, 'Failed to parse Task Metadata Schema file.'
        end

        def validate_target(report, target)
          unless PDK::Util::Filesystem.readable?(target)
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message: 'Could not be read.',
            )
            return 1
          end

          require 'json-schema'
          begin
            # Need to set the JSON Parser and State Generator to the Native one to be
            # compatible with the multi_json adapter.
            JSON.parser = JSON::Ext::Parser if defined?(JSON::Ext::Parser)
            JSON.generator = JSON::Ext::Generator if defined?(JSON::Ext::Generator)

            begin
              errors = JSON::Validator.fully_validate(schema_file, PDK::Util::Filesystem.read_file(target)) || []
            rescue JSON::Schema::SchemaError => e
              raise PDK::CLI::FatalError, 'Unable to validate Task Metadata. %{error}.' % { error: e.message }
            end

            if errors.empty?
              report.add_event(
                file:     target,
                source:   name,
                state:    :passed,
                severity: 'ok',
              )
              return 0
            else
              errors.each do |error|
                # strip off the trailing parts that aren't relevant
                error = error.split('in schema').first if error.include? 'in schema'

                report.add_event(
                  file:     target,
                  source:   name,
                  state:    :failure,
                  severity: 'error',
                  message:  error,
                )
              end
              return 1
            end
          end
        end
      end
    end
  end
end

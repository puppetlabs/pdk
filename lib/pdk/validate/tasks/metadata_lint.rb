require 'pdk'

module PDK
  module Validate
    class Tasks
      class MetadataLint < BaseValidator
        FORGE_SCHEMA_URL = 'https://forgeapi.puppet.com/schemas/task.json'.freeze

        def self.name
          'task-metadata-lint'
        end

        def self.pattern
          'tasks/*.json'
        end

        def self.spinner_text(_targets = [])
          _('Checking task metadata style (%{targets}).') % {
            targets: pattern,
          }
        end

        def self.create_spinner(targets = [], options = {})
          require 'pdk/cli/util'

          return unless PDK::CLI::Util.interactive?

          options = options.merge(PDK::CLI::Util.spinner_opts_for_platform)

          exec_group = options[:exec_group]
          @spinner = if exec_group
                       exec_group.add_spinner(spinner_text(targets), options)
                     else
                       require 'pdk/cli/util/spinner'

                       TTY::Spinner.new("[:spinner] #{spinner_text(targets)}", options)
                     end
          @spinner.auto_spin
        end

        def self.stop_spinner(exit_code)
          if exit_code.zero? && @spinner
            @spinner.success
          elsif @spinner
            @spinner.error
          end
        end

        def self.schema_file
          require 'pdk/util/vendored_file'

          schema = PDK::Util::VendoredFile.new('task.json', FORGE_SCHEMA_URL).read

          JSON.parse(schema)
        rescue PDK::Util::VendoredFile::DownloadError => e
          raise PDK::CLI::FatalError, e.message
        rescue JSON::ParserError
          raise PDK::CLI::FatalError, _('Failed to parse Task Metadata Schema file.')
        end

        def self.invoke(report, options = {})
          targets, skipped, invalid = parse_targets(options)

          process_skipped(report, skipped)
          process_invalid(report, invalid)

          return 0 if targets.empty?

          return_val = 0
          create_spinner(targets, options)

          require 'json-schema'

          targets.each do |target|
            unless PDK::Util::Filesystem.readable?(target)
              report.add_event(
                file:     target,
                source:   name,
                state:    :failure,
                severity: 'error',
                message:  _('Could not be read.'),
              )
              return_val = 1
              next
            end

            begin
              # Need to set the JSON Parser and State Generator to the Native one to be
              # compatible with the multi_json adapter.
              JSON.parser = JSON::Ext::Parser if defined?(JSON::Ext::Parser)
              JSON.generator = JSON::Ext::Generator

              begin
                errors = JSON::Validator.fully_validate(schema_file, PDK::Util::Filesystem.read_file(target)) || []
              rescue JSON::Schema::SchemaError => e
                raise PDK::CLI::FatalError, _('Unable to validate Task Metadata. %{error}.') % { error: e.message }
              end

              if errors.empty?
                report.add_event(
                  file:     target,
                  source:   name,
                  state:    :passed,
                  severity: 'ok',
                )
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
                return_val = 1
              end
            end
          end

          stop_spinner(return_val)
          return_val
        end
      end
    end
  end
end

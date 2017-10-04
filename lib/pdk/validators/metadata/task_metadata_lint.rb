require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pdk/util'
require 'pathname'
require 'json-schema'

module PDK
  module Validate
    class TaskMetadataLint < BaseValidator
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
        return if PDK.logger.debug?
        options = options.merge(PDK::CLI::Util.spinner_opts_for_platform)

        exec_group = options[:exec_group]
        @spinner = if exec_group
                     exec_group.add_spinner(spinner_text(targets), options)
                   else
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

      def self.vendored_task_schema_path
        @vendored_task_schema_path ||= File.join(PDK::Util.package_cachedir, 'task.json')
      end

      def self.schema_file
        schema = if PDK::Util.package_install? && File.exist?(vendored_task_schema_path)
                   File.read(vendored_task_schema_path)
                 else
                   download_schema_from_forge
                 end

        JSON.parse(schema)
      rescue JSON::ParserError
        raise PDK::CLI::FatalError, _('Failed to parse Task Metadata Schema file.')
      end

      def self.download_schema_from_forge
        PDK.logger.debug(_('Task Metadata Schema was not found in the cache. Now downloading from the forge.'))
        ssl_failures ||= 0
        open(FORGE_SCHEMA_URL).read
      rescue OpenSSL::SSL::SSLError => e
        ssl_failures += 1

        unless ssl_failures < 2 && Gem.win_platform? && PDK::Util.gem_install?
          raise PDK::CLI::FatalError, _('Unable to download Task Metadata Schema file. Please check internet connectivity and retry this action. %{error}') % { error: e }
        end

        # Try to get Windows to install the needed SSL CA Cert for Forge
        `powershell Invoke-WebRequest #{FORGE_SCHEMA_URL} | Out-Null`
        retry
      rescue StandardError => e
        raise PDK::CLI::FatalError, _('Unable to download Task Metadata Schema file. Please check internet connectivity and retry this action. %{error}') % { error: e }
      end

      def self.invoke(report, options = {})
        targets, skipped, invalid = parse_targets(options)

        process_skipped(report, skipped)
        process_invalid(report, invalid)

        return 0 if targets.empty?

        return_val = 0
        create_spinner(targets, options)

        targets.each do |target|
          unless File.readable?(target)
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
              errors = JSON::Validator.fully_validate(schema_file, File.read(target)) || []
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

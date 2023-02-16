require 'pdk'

module PDK
  module Validate
    module ControlRepo
      class EnvironmentConfValidator < InternalRubyValidator
        ALLOWED_SETTINGS = %w[modulepath manifest config_version environment_timeout].freeze

        def name
          'environment-conf'
        end

        def valid_in_context?
          context.is_a?(PDK::Context::ControlRepo)
        end

        def pattern
          ['environment.conf']
        end

        def spinner_text
          'Checking Puppet Environment settings (%{patterns}).' % {
            patterns: pattern.join(' '),
          }
        end

        def validate_target(report, target)
          unless PDK::Util::Filesystem.readable?(target)
            report.add_event(
              file: target,
              source: name,
              state: :failure,
              severity: 'error',
              message: 'Could not be read.',
            )
            return 1
          end

          is_valid = true
          begin
            env_conf = PDK::ControlRepo.environment_conf_as_config(target)

            env_conf.resolve.each do |setting_name, setting_value|
              # Remove the 'environment.' setting_name prefix
              setting_name = setting_name.slice(12..-1)
              next if ALLOWED_SETTINGS.include?(setting_name)
              # A hash indicates that the ini file has a section in it.
              message = if setting_value.is_a?(Hash)
                          "Invalid section '%{name}'" % { name: setting_name }
                        else
                          "Invalid setting '%{name}'" % { name: setting_name }
                        end

              report.add_event(
                file:     target,
                source:   name,
                state:    :failure,
                severity: 'error',
                message:  message,
              )
              is_valid = false
            end

            timeout = env_conf.fetch('environment_timeout', nil)
            unless timeout.nil? || timeout == '0' || timeout == 'unlimited'
              report.add_event(
                file:     target,
                source:   name,
                state:    :failure,
                severity: 'error',
                message:  "environment_timeout is set to '%{timeout}' but should be 0, 'unlimited' or not set." % { timeout: timeout },
              )
              is_valid = false
            end

            return 1 unless is_valid
            report.add_event(
              file:     target,
              source:   name,
              state:    :passed,
              severity: 'ok',
            )
            return 0
          rescue StandardError => e
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  e.message,
            )
            return 1
          end
        end
      end
    end
  end
end

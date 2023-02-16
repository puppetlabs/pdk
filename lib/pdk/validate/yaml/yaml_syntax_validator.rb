require 'pdk'

module PDK
  module Validate
    module YAML
      class YAMLSyntaxValidator < InternalRubyValidator
        YAML_ALLOWLISTED_CLASSES = [Symbol].freeze

        def ignore_dotfiles
          false
        end

        def name
          'yaml-syntax'
        end

        def pattern
          [
            '**/*.yaml',
            '**/*.yml',
          ].tap do |pat|
            if context.is_a?(PDK::Context::ControlRepo)
              pat.concat(
                [
                  '**/*.eyaml',
                  '**/*.eyml',
                ],
              )
            else
              pat
            end
          end
        end

        def spinner_text
          'Checking YAML syntax (%{patterns}).' % {
            patterns: pattern.join(' '),
          }
        end

        def validate_target(report, target)
          return 0 unless PDK::Util::Filesystem.file?(target)

          unless PDK::Util::Filesystem.readable?(target)
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  'Could not be read.',
            )
            return 1
          end

          begin
            ::YAML.safe_load(PDK::Util::Filesystem.read_file(target), YAML_ALLOWLISTED_CLASSES, [], true)

            report.add_event(
              file:     target,
              source:   name,
              state:    :passed,
              severity: 'ok',
            )
            return 0
          rescue Psych::SyntaxError => e
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              line:     e.line,
              column:   e.column,
              message:  '%{problem} %{context}' % {
                problem: e.problem,
                context: e.context,
              },
            )
            return 1
          rescue Psych::DisallowedClass => e
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  'Unsupported class: %{message}' % {
                message: e.message,
              },
            )
            return 1
          end
        end
      end
    end
  end
end

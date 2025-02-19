require 'pdk'

module PDK
  module Validate
    module Metadata
      class MetadataSyntaxValidator < InternalRubyValidator
        def name
          'metadata-syntax'
        end

        def pattern
          contextual_pattern(['metadata.json', 'tasks/*.json'])
        end

        def spinner_text
          format('Checking metadata syntax (%{patterns}).', patterns: pattern.join(' '))
        end

        def invoke(report)
          super
        ensure
          JSON.parser = JSON::Ext::Parser if defined?(JSON::Ext::Parser)
        end

        def validate_target(report, target)
          unless PDK::Util::Filesystem.readable?(target)
            report.add_event(
              file: target,
              source: name,
              state: :failure,
              severity: 'error',
              message: 'Could not be read.'
            )
            return 1
          end

          begin
            JSON.parse(PDK::Util::Filesystem.read_file(target))

            report.add_event(
              file: target,
              source: name,
              state: :passed,
              severity: 'ok'
            )
            0
          rescue JSON::ParserError => e
            # Because the message contains a raw segment of the file, we use
            # String#dump here to unescape any escape characters like newlines.
            sane_message = e.message.dump

            report.add_event(
              file: target,
              source: name,
              state: :failure,
              severity: 'error',
              message: sane_message
            )
            1
          end
        end
      end
    end
  end
end

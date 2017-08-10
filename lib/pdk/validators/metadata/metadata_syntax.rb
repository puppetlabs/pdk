require 'pdk'
require 'pdk/cli/exec'
require 'pdk/validators/base_validator'
require 'pathname'

module PDK
  module Validate
    class MetadataSyntax < BaseValidator
      def self.name
        'metadata-syntax'
      end

      def self.pattern
        'metadata.json'
      end

      def self.spinner_text(targets = [])
        _('Checking metadata syntax (%{targets})') % {
          targets: PDK::Util.targets_relative_to_pwd(targets).join(' '),
        }
      end

      def self.create_spinner(targets = [], options = {})
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

      def self.invoke(report, options = {})
        targets = parse_targets(options)

        return 0 if targets.empty?

        return_val = 0
        create_spinner(targets, options)

        # The pure ruby JSON parser gives much nicer parse error messages than
        # the C extension at the cost of slightly slower parsing. We require it
        # here and restore the C extension at the end of the method (if it was
        # being used).
        require 'json/pure'
        JSON.parser = JSON::Pure::Parser

        targets.each do |target|
          unless File.file?(target)
            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  _('not a file'),
            )
            return_val = 1
            next
          end

          unless File.readable?(target)
            report.add_event(
              file: target,
              source: name,
              state: :failure,
              severity: 'error',
              message: _('could not be read'),
            )
            return_val = 1
            next
          end

          begin
            JSON.parse(File.read(target))

            report.add_event(
              file:     target,
              source:   name,
              state:    :passed,
              severity: 'ok',
            )
          rescue JSON::ParserError => e
            # Because the message contains a raw segment of the file, we use
            # String#dump here to unescape any escape characters like newlines.
            # We then strip out the surrounding quotes and the exclaimation
            # point that json_pure likes to put in exception messages.
            sane_message = e.message.dump[%r{\A"(.+?)!?"\Z}, 1]

            report.add_event(
              file:     target,
              source:   name,
              state:    :failure,
              severity: 'error',
              message:  sane_message,
            )
            return_val = 1
          end
        end

        stop_spinner(return_val)
        return_val
      ensure
        JSON.parser = JSON::Ext::Parser if defined?(JSON::Ext::Parser)
      end
    end
  end
end

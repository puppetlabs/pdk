require 'cri'

require 'pdk/cli/errors'
require 'pdk/cli/util/option_validator'
require 'pdk/cli/util/option_normalizer'
require 'pdk/logger'
require 'pdk/report'

require 'pdk/cli/new'
require 'pdk/cli/validate'
require 'pdk/cli/test'

module PDK
  module CLI
    def self.base_command
      @base ||= Cri::Command.new.tap do |cmd|
        cmd.modify do
          name 'pdk'
          usage _("pdk command [options]")
          summary _("Puppet Development Kit")
          description _("The shortest path to better modules.")

          flag :h, :help, _("show help for this command") do |_, c|
            puts c.help
            exit 0
          end

          format_desc = _(
            "Specify desired output format. Valid formats are '%{available_formats}'. " +
            "You may also specify a file to which the formatted output will be directed, " +
            "for example: '--format=junit:report.xml'. This option may be specified " +
            "multiple times as long as each option specifies a distinct target file."
          ) % {available_formats: PDK::Report.formats.join("', '")}

          option :f, :format, format_desc, { argument: :required, multiple: true } do |values|
            values.compact.each do |v|
              if v.include?(':')
                format = v.split(':', 2).first

                PDK::CLI::Util::OptionValidator.enum(format, PDK::Report.formats)
              else
                PDK::CLI::Util::OptionValidator.enum(v, PDK::Report.formats)
              end
            end
          end

          flag :d, :debug, _("Enable debug output.") do |_, _|
            PDK.logger.enable_debug_output
          end
        end

        cmd.add_command(Cri::Command.new_basic_help)

        cmd.add_command(PDK::CLI::New.command)
        cmd.add_command(PDK::CLI::Validate.command)
        cmd.add_command(PDK::CLI::Test.command)
      end
    end

    def self.run(args)
      base_command.run(args)
    rescue PDK::CLI::FatalError => e
      PDK.logger.fatal(e.message) if e.message

      # If FatalError was raised as the result of another exception, send the
      # details of that exception to the debug log. If there was no cause
      # (FatalError raised on its own outside a rescue block), send the details
      # of the FatalError exception to the debug log.
      cause = e.cause
      if cause.nil?
        e.backtrace.each { |line| PDK.logger.debug(line) }
      else
        PDK.logger.debug("#{cause.class}: #{cause.message}")
        cause.backtrace.each { |line| PDK.logger.debug(line) }
      end

      exit e.exit_code
    end
  end
end

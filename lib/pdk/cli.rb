require 'cri'

require 'pdk/cli/util/option_validator'
require 'pdk/report'

require 'pdk/cli/generate'
require 'pdk/cli/validate'

module PDK
  module CLI
    def self.base_command
      @base ||= Cri::Command.new.tap do |cmd|
        cmd.modify do
          name 'pdk'
          usage 'pdk [options]'
          summary 'Puppet SDK'
          description 'The shortest path to better modules.'

          flag :h, :help, 'show help for this command' do |_, c|
            puts c.help
            exit 0
          end

          option nil, :'report-file', 'report-file', argument: :required
          option nil, :'report-format', 'report-format', argument: :required do |value|
            PDK::CLI::Util::OptionValidator.enum(value, PDK::Report.formats)
          end
        end

        cmd.add_command(Cri::Command.new_basic_help)

        cmd.add_command(PDK::CLI::Validate.command)
        cmd.add_command(PDK::CLI::Generate.command)
      end
    end

    def self.run(args)
      base_command.run(args)
    end
  end
end

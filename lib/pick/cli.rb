require 'cri'

require 'pick/cli/util/option_validator'
require 'pick/report'

require 'pick/cli/generate'
require 'pick/cli/validate'

module Pick
  module CLI
    def self.base_command
      @base ||= Cri::Command.new.tap do |cmd|
        cmd.modify do
          name 'pick'
          usage 'pick [options]'
          summary 'Puppet SDK'
          description 'The shortest path to better modules.'

          flag :h, :help, 'show help for this command' do |_, c|
            puts c.help
            exit 0
          end

          option nil, :'report-file', 'report-file', argument: :required
          option nil, :'report-format', 'report-format', argument: :required do |value|
            Pick::CLI::Util::OptionValidator.enum(value, Pick::Report.formats)
          end
        end

        cmd.add_command(Cri::Command.new_basic_help)

        cmd.add_command(Pick::CLI::Validate.command)
        cmd.add_command(Pick::CLI::Generate.command)
      end
    end

    def self.run(args)
      base_command.run(args)
    end
  end
end

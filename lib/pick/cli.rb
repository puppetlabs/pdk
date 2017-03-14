require 'pick'
require 'pick/cli/generate'
require 'pick/cli/validate'
require 'cri'

module Pick
  module CLI
    def self.base_command
      @base ||= Cri::Command.define do
        name 'pick'
        usage 'pick [options]'
        summary 'Puppet SDK'
        description 'The shortest path to better modules.'

        flag   :h,  :help,  'show help for this command' do |value, cmd|
          puts cmd.help
          exit 0
        end

        option nil, :'report-file', 'report-file', argument: :required
        option nil, :'report-format', 'report-format', argument: :required do |value|
          Pick::CLI::Util::OptionValidator.enum(value, Pick::Report.formats)
        end
      end

      @base.add_command(Pick::CLI::Validate.command)
      @base.add_command(Pick::CLI::Generate.command)
      @base
    end

    def self.run(*args)
      base_command.run(*args)
    end
  end
end

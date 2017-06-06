require 'cri'
require 'pdk/cli/new/module'
require 'pdk/cli/new/class'

module PDK
  module CLI
    module New
      def self.command
        @new ||= Cri::Command.new.tap do |cmd|
          cmd.modify do
            name 'new'
            usage _('new <type> [options]')
            summary _('create a new module, etc.')
            description _('Creates a new instance of <type> using the options relevant to that type of thing')

            # print the help text for the 'new' sub command if no type has been
            # provided.
            run do |_opts, _args, _cmd|
              puts command.help
              exit 1
            end
          end

          cmd.add_command(PDK::CLI::New::Module.command)
          cmd.add_command(PDK::CLI::New::PuppetClass.command)
        end
      end
    end
  end
end

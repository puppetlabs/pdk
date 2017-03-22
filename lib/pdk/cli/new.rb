require 'cri'
require 'pdk/cli/new/module'

module PDK
  module CLI
    module New
      def self.command
        @new ||= Cri::Command.new.tap do |cmd|
          cmd.modify do
            name 'new'
            usage 'new <type> [options]'
            summary 'create a new module, etc.'
            description 'Creates a new instance of <type> using the options relevant to that type of thing'
          end

          cmd.add_command(PDK::CLI::New::Module.command)
        end
      end
    end
  end
end

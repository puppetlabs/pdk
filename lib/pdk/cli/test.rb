require 'cri'
require 'pdk/cli/tests/unit'
require 'pdk/report'


module PDK
  module CLI
    module Test

      def self.command
        @test ||= Cri::Command.new.tap do |cmd|
          cmd.modify do
            name 'test'
            usage 'test [type] [options]'
            summary 'Run tests.'
          end

          cmd.add_command(PDK::CLI::Test::Unit.command)
        end
      end
    end
  end
end

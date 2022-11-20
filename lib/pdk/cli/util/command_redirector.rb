require 'pdk'
require 'tty/prompt'

module PDK
  module CLI
    module Util
      class CommandRedirector < TTY::Prompt::AnswersCollector
        attr_accessor :command

        def pastel
          @pastel ||= Pastel.new
        end

        def target_command(cmd)
          @command = cmd
        end

        def run
          @prompt.puts 'Did you mean \'%{command}\'?' % { command: pastel.bold(@command) }
          @prompt.yes?('-->')
        rescue PDK::CLI::Util::Interview::READER::InputInterrupt
          nil
        end
      end
    end
  end
end

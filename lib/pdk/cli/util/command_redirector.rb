# frozen_string_literal: true

require 'tty-prompt'

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
          @prompt.puts _('Did you mean \'%{command}\'?') % { command: pastel.bold(@command) }
          @prompt.yes?('-->')
        rescue TTY::Prompt::Reader::InputInterrupt
          nil
        end
      end
    end
  end
end

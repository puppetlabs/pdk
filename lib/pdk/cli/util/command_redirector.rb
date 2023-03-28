require 'pdk'
require 'tty/prompt'

module PDK
  module CLI
    module Util
      class CommandRedirector < TTY::Prompt::AnswersCollector
        attr_accessor :command

        # Override the initialize method because the original one
        # doesn't work with Ruby 3.
        # rubocop:disable Lint/MissingSuper
        def initialize(prompt, options = {})
          @prompt  = prompt
          @answers = options.fetch(:answers) { {} }
        end
        # rubocop:enable Lint/MissingSuper

        def pastel
          @pastel ||= Pastel.new
        end

        def target_command(cmd)
          @command = cmd
        end

        def run
          @prompt.puts "Did you mean '#{pastel.bold(@command)}'?"
          @prompt.yes?('-->')
        rescue PDK::CLI::Util::Interview::READER::InputInterrupt
          nil
        end
      end
    end
  end
end

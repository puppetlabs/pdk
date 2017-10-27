module PDK
  module CLI
    module Util
      # Ensures the calling code is being run from inside a module directory.
      #
      # @raise [PDK::CLI::ExitWithError] if the current directory or parents do
      #   not contain a `metadata.json` file.
      def ensure_in_module!
        message = _('This command must be run from inside a valid module (no metadata.json found).')
        raise PDK::CLI::ExitWithError, message if PDK::Util.module_root.nil?
      end
      module_function :ensure_in_module!

      def spinner_opts_for_platform
        windows_opts = {
          success_mark: '*',
          error_mark: 'X',
        }

        return windows_opts if Gem.win_platform?
        {}
      end
      module_function :spinner_opts_for_platform

      def prompt_for_yes(question_text, opts = {})
        prompt = opts[:prompt] || TTY::Prompt.new(help_color: :cyan)
        validator = proc { |value| [true, false].include?(value) || value =~ %r{\A(?:yes|y|no|n)\Z}i }
        response = nil

        begin
          response = prompt.yes?(question_text) do |q|
            q.validate(validator, _('Answer "Y" to continue or "n" to cancel.'))
          end
        rescue TTY::Prompt::Reader::InputInterrupt
          PDK.logger.info opts[:cancel_message] if opts[:cancel_message]
        end

        response
      end
      module_function :prompt_for_yes
    end
  end
end

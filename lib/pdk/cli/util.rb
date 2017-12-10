module PDK
  module CLI
    module Util
      MODULE_FOLDERS = %w[
        manifests
        lib
        tasks
        facts.d
        functions
        types
      ].freeze

      # Ensures the calling code is being run from inside a module directory.
      #
      # @param opts [Hash] options to change the behavior of the check logic.
      # @option opts [Boolean] :check_module_layout Set to true to check for
      #   stardard module folder layout if the module does not contain
      #   a metadata.json file.
      #
      # @raise [PDK::CLI::ExitWithError] if the current directory does not
      #   contain a Puppet module.
      def ensure_in_module!(opts = {})
        return unless PDK::Util.module_root.nil?
        return if opts[:check_module_layout] && PDK::CLI::Util::MODULE_FOLDERS.any? { |dir| File.directory?(dir) }

        message = _('This command must be run from inside a valid module (no metadata.json found).')
        raise PDK::CLI::ExitWithError, message
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

      def interactive?
        return false if PDK.logger.debug?
        return !ENV['PDK_FRONTEND'].casecmp('noninteractive').zero? if ENV['PDK_FRONTEND']
        return false unless $stderr.isatty

        true
      end
      module_function :interactive?
    end
  end
end

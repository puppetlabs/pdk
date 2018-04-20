module PDK
  module CLI
    module Util
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
        return if opts[:check_module_layout] && PDK::Util.in_module_root?

        message = opts.fetch(:message, _('This command must be run from inside a valid module (no metadata.json found).'))
        raise PDK::CLI::ExitWithError.new(message, opts)
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
            q.default opts[:default] unless opts[:default].nil?
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

      def module_version_check
        module_pdk_ver = PDK::Util.module_pdk_version

        # This means the module does not have a pdk-version tag in the metadata.json
        # and will require a pdk convert.
        if module_pdk_ver.nil?
          PDK.logger.warn _('This module is not PDK compatible. Run `pdk convert` to make it compatible with your version of PDK.')
        # This checks that the version of pdk in the module's metadata is older
        # than 1.3.1, which means the module will need to run pdk convert to the
        # new templates.
        elsif Gem::Version.new(module_pdk_ver) < Gem::Version.new('1.3.1')
          PDK.logger.warn _('This module template is out of date. Run `pdk convert` to make it compatible with your version of PDK.')
        # This checks if the version of the installed PDK is older than the
        # version in the module's metadata, and advises the user to upgrade to
        # their install of PDK.
        elsif Gem::Version.new(PDK::VERSION) < Gem::Version.new(module_pdk_ver)
          PDK.logger.warn _('This module is compatible with a newer version of PDK. Upgrade your version of PDK to ensure compatibility.')
        # This checks if the version listed in the module's metadata is older
        # than the installed PDK, and advises the user to run pdk update.
        elsif Gem::Version.new(PDK::VERSION) > Gem::Version.new(module_pdk_ver)
          PDK.logger.warn _('This module is compatible with an older version of PDK. Run `pdk update` to update it to your version of PDK.')
        end
      end
      module_function :module_version_check
    end
  end
end

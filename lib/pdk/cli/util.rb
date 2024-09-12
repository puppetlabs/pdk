require 'pdk'

module PDK
  module CLI
    module Util
      autoload :CommandRedirector, 'pdk/cli/util/command_redirector'
      autoload :OptionNormalizer, 'pdk/cli/util/option_normalizer'
      autoload :OptionValidator, 'pdk/cli/util/option_validator'
      autoload :Interview, 'pdk/cli/util/interview'
      autoload :Spinner, 'pdk/cli/util/spinner'
      autoload :UpdateManagerPrinter, 'pdk/cli/util/update_manager_printer'

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

        message = opts.fetch(:message, 'This command must be run from inside a valid module (no metadata.json found).')
        raise PDK::CLI::ExitWithError.new(message, opts)
      end
      module_function :ensure_in_module!

      def prompt_for_yes(question_text, opts = {})
        require 'tty/prompt'

        prompt = opts[:prompt] || TTY::Prompt.new(help_color: :cyan)
        validator = proc { |value| [true, false].include?(value) || value =~ /\A(?:yes|y|no|n)\Z/i }
        response = nil

        begin
          response = prompt.yes?(question_text) do |q|
            q.default opts[:default] unless opts[:default].nil?
            q.validate(validator, 'Answer "Y" to continue or "n" to cancel.')
          end
        rescue PDK::CLI::Util::Interview::READER::InputInterrupt
          PDK.logger.info opts[:cancel_message] if opts[:cancel_message]
        end

        response
      end
      module_function :prompt_for_yes

      # Uses environment variables to detect if the current process is running in common
      # Continuous Integration (CI) environments
      # @return [Boolean] Whether the PDK is in a CI based environment
      def ci_environment?
        [
          'CI',                     # Generic
          'CONTINUOUS_INTEGRATION', # Generic
          'APPVEYOR_BUILD_FOLDER',  # AppVeyor CI
          'GITLAB_CI',              # GitLab CI
          'JENKINS_URL',            # Jenkins
          'BUILD_DEFINITIONNAME',   # Azure Pipelines
          'TEAMCITY_VERSION',       # Team City
          'BAMBOO_BUILDKEY',        # Bamboo
          'GOCD_SERVER_URL',        # Go CD
          'TRAVIS',                 # Travis CI
          'GITHUB_WORKFLOW' # GitHub Actions
        ].any? { |name| PDK::Util::Env.key?(name) }
      end
      module_function :ci_environment?

      def interactive?
        require 'pdk/logger'

        return false if PDK.logger.debug?
        return !PDK::Util::Env['PDK_FRONTEND'].casecmp('noninteractive').zero? if PDK::Util::Env['PDK_FRONTEND']
        return false if ci_environment?
        return false unless $stderr.isatty

        true
      end
      module_function :interactive?

      def module_version_check
        module_pdk_ver = PDK::Util.module_pdk_version

        # This means the module does not have a pdk-version tag in the metadata.json
        # and will require a pdk convert.
        raise PDK::CLI::ExitWithError, 'This module is not PDK compatible. Run `pdk convert` to make it compatible with your version of PDK.' if module_pdk_ver.nil?

        # This checks that the version of pdk in the module's metadata is older
        # than 1.3.1, which means the module will need to run pdk convert to the
        # new templates.
        if Gem::Version.new(module_pdk_ver) < Gem::Version.new('1.3.1')
          PDK.logger.warn 'This module template is out of date. Run `pdk convert` to make it compatible with your version of PDK.'
        # This checks if the version of the installed PDK is older than the
        # version in the module's metadata, and advises the user to upgrade to
        # their install of PDK.
        elsif Gem::Version.new(PDK::VERSION) < Gem::Version.new(module_pdk_ver)
          PDK.logger.warn 'This module is compatible with a newer version of PDK. Upgrade your version of PDK to ensure compatibility.'
        # This checks if the version listed in the module's metadata is older
        # than the installed PDK, and advises the user to run pdk update.
        elsif Gem::Version.new(PDK::VERSION) > Gem::Version.new(module_pdk_ver)
          message = 'This module is compatible with an older version of PDK.'
          message = 'Module templates older than 3.0.0 may experience issues.' if Gem::Version.new(module_pdk_ver) < Gem::Version.new('3.0.0')

          PDK.logger.warn "#{message} Run `pdk update` to update it to the latest version."
        end
      end
      module_function :module_version_check

      def check_for_deprecated_puppet(version)
        return unless version.is_a?(Gem::Version)

        deprecated_below = Gem::Version.new('7.0.0')
        return unless version < deprecated_below

        raise PDK::CLI::ExitWithError, "Support for Puppet versions older than #{deprecated_below} has been removed from PDK."
      end
      module_function :check_for_deprecated_puppet

      # @param opts [Hash] - the pdk options to use, defaults to empty hash
      # @option opts [String] :'puppet-dev' Use the puppet development version, default to PDK_PUPPET_DEV env
      # @option opts [String] :'puppet-version' Puppet version to use, default to PDK_PUPPET_VERSION env
      # @option opts [String] :'pe-version' PE Puppet version to use, default to PDK_PE_VERSION env
      # @param logging_disabled [Boolean] - disable logging of PDK info
      # @param context [PDK::Context::AbstractContext] - The context the PDK is running in
      # @return [Hash] - return hash of { gemset: <>, ruby_version: 2.x.x }
      def puppet_from_opts_or_env(opts, logging_disabled = false, context = PDK.context)
        opts ||= {}
        use_puppet_dev = opts.fetch(:'puppet-dev', PDK::Util::Env['PDK_PUPPET_DEV'])
        desired_puppet_version = opts.fetch(:'puppet-version', PDK::Util::Env['PDK_PUPPET_VERSION'])
        desired_pe_version = opts.fetch(:'pe-version', PDK::Util::Env['PDK_PE_VERSION'])

        begin
          puppet_env =
            if use_puppet_dev
              PDK::Util::PuppetVersion.fetch_puppet_dev(run: :once)
              PDK::Util::PuppetVersion.puppet_dev_env
            elsif desired_puppet_version
              PDK::Util::PuppetVersion.find_gem_for(desired_puppet_version)
            elsif desired_pe_version
              PDK::Util::PuppetVersion.from_pe_version(desired_pe_version)
            elsif context.is_a?(PDK::Context::Module)
              PDK::Util::PuppetVersion.from_module_metadata || PDK::Util::PuppetVersion.latest_available
            else
              PDK::Util::PuppetVersion.latest_available
            end
        rescue ArgumentError => e
          raise PDK::CLI::ExitWithError, e.message
        end

        # Notify user of what Ruby version will be used.
        PDK.logger.info(format('Using Ruby %{version}', version: puppet_env[:ruby_version])) unless logging_disabled

        check_for_deprecated_puppet(puppet_env[:gem_version])

        gemset = { puppet: puppet_env[:gem_version].to_s }

        # Notify user of what gems are being activated.
        unless logging_disabled
          gemset.each do |gem, version|
            next if version.nil?

            PDK.logger.info(format('Using %{gem} %{version}', gem: gem.to_s.capitalize, version: version))
          end
        end

        {
          gemset: gemset,
          ruby_version: puppet_env[:ruby_version]
        }
      end
      module_function :puppet_from_opts_or_env

      def validate_puppet_version_opts(opts)
        puppet_ver_specs = []
        puppet_ver_specs << '--puppet-version option' if opts[:'puppet-version']
        puppet_ver_specs << 'PDK_PUPPET_VERSION environment variable' if PDK::Util::Env['PDK_PUPPET_VERSION'] && !PDK::Util::Env['PDK_PUPPET_VERSION'].empty?

        pe_ver_specs = []
        pe_ver_specs << '--pe-version option' if opts[:'pe-version']
        pe_ver_specs << 'PDK_PE_VERSION environment variable' if PDK::Util::Env['PDK_PE_VERSION'] && !PDK::Util::Env['PDK_PE_VERSION'].empty?

        puppet_dev_specs = []
        puppet_dev_specs << '--puppet-dev flag' if opts[:'puppet-dev']
        puppet_dev_specs << 'PDK_PUPPET_DEV environment variable' if PDK::Util::Env['PDK_PUPPET_DEV'] && !PDK::Util::Env['PDK_PUPPET_DEV'].empty?

        puppet_dev_specs.each do |pup_dev_spec|
          [puppet_ver_specs, pe_ver_specs].each do |offending|
            next if offending.empty?

            raise PDK::CLI::ExitWithError, format('You cannot specify a %{first} and %{second} at the same time.', first: pup_dev_spec, second: offending.first)
          end
        end

        puppet_ver_specs.each do |pup_ver_spec|
          next if pe_ver_specs.empty?

          offending = [pup_ver_spec, pe_ver_specs[0]].sort

          raise PDK::CLI::ExitWithError, format('You cannot specify a %{first} and %{second} at the same time.', first: offending[0], second: offending[1])
        end

        # We want to mark setting the PE as deprecated.
        if opts[:'pe-version'] || PDK::Util::Env['PDK_PE_VERSION']
          PDK.logger.warn('Specifying a Puppet Enterprise version is now deprecated and will be removed in a future version. Please use --puppet-version or PDK_PUPPET_VERSION instead.')
        end

        if puppet_dev_specs.size == 2
          warning_str = 'Puppet dev flag from command line: "--puppet-dev" '
          warning_str += 'overrides value from environment: "PDK_PUPPET_DEV=true". You should not specify both.'

          PDK.logger.warn(format(warning_str, pup_ver_opt: opts[:'puppet-dev'], pup_ver_env: PDK::Util::Env['PDK_PUPPET_DEV']))
        elsif puppet_ver_specs.size == 2
          warning_str = 'Puppet version option from command line: "--puppet-version=%{pup_ver_opt}" '
          warning_str += 'overrides value from environment: "PDK_PUPPET_VERSION=%{pup_ver_env}". You should not specify both.'

          PDK.logger.warn(format(warning_str, pup_ver_opt: opts[:'puppet-version'], pup_ver_env: PDK::Util::Env['PDK_PUPPET_VERSION']))
        elsif pe_ver_specs.size == 2
          warning_str = 'Puppet Enterprise version option from command line: "--pe-version=%{pe_ver_opt}" '
          warning_str += 'overrides value from environment: "PDK_PE_VERSION=%{pe_ver_env}". You should not specify both.'

          PDK.logger.warn(format(warning_str, pe_ver_opt: opts[:'pe-version'], pe_ver_env: PDK::Util::Env['PDK_PE_VERSION']))
        end
      end
      module_function :validate_puppet_version_opts

      def validate_template_opts(opts)
        raise PDK::CLI::ExitWithError, '--template-ref requires --template-url to also be specified.' if opts[:'template-ref'] && opts[:'template-url'].nil?

        return unless opts[:'template-url']&.include?('#')

        raise PDK::CLI::ExitWithError, '--template-url may not be used to specify paths containing #\'s.'
      end
      module_function :validate_template_opts
    end
  end
end

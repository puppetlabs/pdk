module PDK::CLI
  @console_cmd = @base_cmd.define_command do
    name 'console'
    usage 'console [console_options]'
    summary '(Experimental) Start a session of the puppet debugger console.'
    default_subcommand 'help'
    description <<-EOF
The pdk console runs a interactive session of the puppet debugger tool to test out snippets of code, run
language evaluations, datatype prototyping and much more.  A virtual playground for your puppet code!
For usage details see the puppet debugger docs at https://docs.puppet-debugger.com.

EOF

    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)
    # we have to skip option parsing because it is expected the user
    # will be passing additional args that are passed to the debugger
    skip_option_parsing

    # TODO: using -h or --help skips the pdk help and passes to puppet debugger help
    run do |_opts, args, _cmd|
      require 'pdk/cli/util'
      require 'pdk/util'

      PDK::CLI::Util.ensure_in_module!(
        message: 'Console can only be run from inside a valid module directory',
        log_level: :fatal,
      )

      PDK::CLI::Util.module_version_check

      processed_options, processed_args = process_opts(args)

      PDK::CLI::Util.validate_puppet_version_opts(processed_options)

      PDK::CLI::Util.analytics_screen_view('console', args)

      # TODO: figure out if we need to remove default configs set by puppet
      # so it is scoped for the module only
      # "--environmentpath"...
      flags = if PDK::Util.in_module_root?
                ["--basemodulepath=#{base_module_path}",
                 "--modulepath=#{base_module_path}"]
              else
                []
              end
      debugger_args = ['debugger'] + processed_args + flags
      result = run_in_module(processed_options, debugger_args)

      exit result[:exit_code]
    end

    # Logs a fatal message about the gem missing and how to add it
    def inform_user_for_missing_gem(gem_name = 'puppet-debugger', version = '~> 0.14')
      PDK.logger.fatal(<<-EOF
Your Gemfile is missing the #{gem_name} gem.  You can add the missing gem
by updating your #{File.join(PDK::Util.module_root, '.sync.yml')} file with the following
and running pdk update.

Gemfile:
  required:
    ":development":
      - gem: #{gem_name}
        version: \"#{version}\"

EOF
                      )
    end

    # @return [Boolean] - true if the gem was found in the lockfile
    # @param [String] - name of ruby gem to check in bundle lockfile
    def gem_in_bundle_lockfile?(gem_name)
      require 'bundler'
      require 'pdk/util/bundler'

      lock_file_path = PDK::Util::Bundler::BundleHelper.new.gemfile_lock
      PDK.logger.debug("Checking lockfile #{lock_file_path} for #{gem_name}")
      lock_file = ::Bundler::LockfileParser.new(::Bundler.read_file(lock_file_path))
      !lock_file.specs.find { |spec| spec.name.eql?(gem_name) }.nil?
    rescue ::Bundler::GemfileNotFound => e
      PDK.logger.debug e.message
      false
    end

    def check_fixtures_dir
      existing_path = base_module_path.split(':').find do |path|
        PDK::Util::Filesystem.directory?(path) && Dir.entries(path).length > 2
      end
      PDK.logger.warn 'Module fixtures not found, please run pdk bundle exec rake spec_prep.' unless existing_path
    end

    # @return [Array] - array of split options [{:"puppet-version"=>"6.9.0"}, ['--loglevel=debug']]
    # options are for the pdk and debugger pass through
    def process_opts(opts)
      args = opts.map do |e|
        if e =~ %r{\A-{2}puppet|pe\-version|dev}
          value = e.split('=')
          (value.count < 2) ? value + [''] : value
        end
      end
      args = args.compact.to_h
      # symbolize keys
      args = args.inject({}) do |memo, (k, v)| # rubocop:disable Style/EachWithObject
        memo[k.sub('--', '').to_sym] = v
        memo
      end
      # pass through all other args that are bound for puppet debugger
      processed_args = opts.map { |e| e unless e =~ %r{\A-{2}puppet|pe\-version|dev} }.compact
      [args, processed_args]
    end

    # @param opts [Hash] - the options passed into the CRI command
    # @param bundle_args [Array] array of bundle exec args and puppet debugger args
    # @return [Hash] - a command result hash
    def run_in_module(opts, bundle_args)
      require 'pdk/cli/exec'
      require 'pdk/cli/exec/interactive_command'
      require 'pdk/util/ruby_version'
      require 'pdk/util/bundler'

      check_fixtures_dir
      output = opts[:debug].nil?
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts, output)
      gemfile_env = PDK::Util::Bundler::BundleHelper.gemfile_env(puppet_env[:gemset])
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
      PDK::Util::RubyVersion.instance(puppet_env[:ruby_version])
      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])
      unless gem_in_bundle_lockfile?('puppet-debugger')
        inform_user_for_missing_gem
        return { exit_code: 1 }
      end

      debugger_args = %w[exec puppet] + bundle_args
      command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, *debugger_args).tap do |c|
        c.context = :pwd
        c.update_environment(gemfile_env)
      end
      command.execute!
    end

    # @return [String] - the basemodulepath of the fixtures and modules from the current module
    # also includes ./modules in case librarian puppet is used
    def base_module_path
      base_module_path = File.join(PDK::Util.module_fixtures_dir, 'modules')
      "#{base_module_path}:#{File.join(PDK::Util.module_root, 'modules')}"
    end
  end
end

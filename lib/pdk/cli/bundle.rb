module PDK::CLI
  @bundle_cmd = @base_cmd.define_command do
    name 'bundle'
    usage 'bundle [bundler_options]'
    summary '(Experimental) Command pass-through to bundler'
    description <<-EOF
[experimental] For advanced users, pdk bundle runs arbitrary commands in the bundler environment that pdk manages.
Careless use of this command can lead to errors that pdk can't help recover from.
EOF
    skip_option_parsing

    run do |_opts, args, _cmd|
      require 'pdk/cli/exec/interactive_command'
      require 'pdk/util/bundler'

      PDK::CLI::Util.ensure_in_module!(
        message: '`pdk bundle` can only be run from inside a valid module directory.',
      )

      PDK::CLI::Util.validate_puppet_version_opts({})

      screen_view_name = ['bundle']
      screen_view_name << args[0] if args.size >= 1
      screen_view_name << args[1] if args.size >= 2 && args[0] == 'exec'

      PDK::CLI::Util.analytics_screen_view(screen_view_name.join('_'))

      # Ensure that the correct Ruby is activated before running command.
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env({})
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

      gemfile_env = PDK::Util::Bundler::BundleHelper.gemfile_env(puppet_env[:gemset])

      require 'pdk/cli/exec'
      require 'pdk/cli/exec/interactive_command'

      command = PDK::CLI::Exec::InteractiveCommand.new(PDK::CLI::Exec.bundle_bin, *args).tap do |c|
        c.context = :pwd
        c.update_environment(gemfile_env)
      end

      result = command.execute!

      exit result[:exit_code]
    end
  end
end

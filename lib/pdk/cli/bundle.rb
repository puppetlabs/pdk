
module PDK::CLI
  @bundle_cmd = @base_cmd.define_command do
    name 'bundle'
    usage _('bundle [bundler_options]')
    summary _('(Experimental) Command pass-through to bundler')
    description _(<<-EOF
[experimental] For advanced users, pdk bundle runs arbitrary commands in the bundler environment that pdk manages.
Careless use of this command can lead to errors that pdk can't help recover from.

Note that for PowerShell the '--' needs to be escaped using a backtick: '`--' to avoid it being parsed by the shell.
EOF
                 )
    skip_option_parsing

    run do |_opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!(
        message: _('`pdk bundle` can only be run from inside a valid module directory.'),
      )

      PDK::CLI::Util.validate_puppet_version_opts({})

      # Ensure that the correct Ruby is activated before running commend.
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env({})
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

      gemfile_env = PDK::Util::Bundler::BundleHelper.gemfile_env(puppet_env[:gemset])

      command = PDK::CLI::Exec::Command.new(PDK::CLI::Exec.bundle_bin, *args).tap do |c|
        c.context = :module
        c.update_environment(gemfile_env)
      end

      result = command.execute!

      $stderr.puts result[:stdout]
      $stderr.puts result[:stderr]

      exit result[:exit_code]
    end
  end
end

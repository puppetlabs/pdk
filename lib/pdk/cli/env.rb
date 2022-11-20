module PDK::CLI
  @env_cmd = @base_cmd.define_command do
    name 'env'
    usage 'env'
    summary '(Experimental) Output environment variables for specific Puppet context'
    description <<-EOF
[experimental] Aids in setting a CLI context for a specified version of Puppet by outputting export commands for necessary environment variables.
EOF

    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)

    run do |opts, _args, _cmd|
      require 'pdk/util'
      require 'pdk/util/ruby_version'

      PDK::CLI::Util.validate_puppet_version_opts(opts)

      PDK::CLI::Util.analytics_screen_view('env')

      # Ensure that the correct Ruby is activated before running command.
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

      resolved_env = {
        'PDK_RESOLVED_PUPPET_VERSION' => puppet_env[:gemset][:puppet],
        'PDK_RESOLVED_RUBY_VERSION' => puppet_env[:ruby_version],
      }

      resolved_env['GEM_HOME'] = PDK::Util::RubyVersion.gem_home
      gem_path = PDK::Util::RubyVersion.gem_path
      resolved_env['GEM_PATH'] = gem_path.empty? ? resolved_env['GEM_HOME'] : gem_path

      # Make sure invocation of Ruby prefers our private installation.
      package_binpath = PDK::Util.package_install? ? File.join(PDK::Util.pdk_package_basedir, 'bin') : nil

      resolved_env['PATH'] = [
        PDK::Util::RubyVersion.bin_path,
        File.join(resolved_env['GEM_HOME'], 'bin'),
        PDK::Util::RubyVersion.gem_paths_raw.map { |gem_path_raw| File.join(gem_path_raw, 'bin') },
        package_binpath,
        PDK::Util::Env['PATH'],
      ].compact.flatten.join(File::PATH_SEPARATOR)

      resolved_env.each do |var, val|
        puts "export #{var}=\"#{val}\""
      end
      exit 0
    end
  end
end

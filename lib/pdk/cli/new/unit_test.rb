module PDK::CLI
  @new_define_cmd = @new_cmd.define_command do
    name 'unit_test'
    usage _('unit_test [options] <name>')
    summary _('Create a new unit test for the object named <name> using given options')
    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)

    run do |opts, args, _cmd|
      PDK::CLI::Util.validate_puppet_version_opts(opts)
      PDK::CLI::Util.ensure_in_module!(
        message: _('Unit tests can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      object_name = args[0]
      module_dir = Dir.pwd

      if object_name.nil? || object_name.empty?
        puts command.help
        exit 1
      end

      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
      PDK::Util::PuppetVersion.fetch_puppet_dev if opts[:'puppet-dev']
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      begin
        generator, obj = PDK::Util::PuppetStrings.find_object(object_name)

        PDK::CLI::Util.analytics_screen_view('new_unit_test', opts)

        generator.new(module_dir, obj['name'], opts.merge(spec_only: true)).run
      rescue PDK::Util::PuppetStrings::NoObjectError
        raise PDK::CLI::ExitWithError, _('Unable to find anything called "%{object}" to generate unit tests for.') % { object: object_name }
      rescue PDK::Util::PuppetStrings::NoGeneratorError => e
        raise PDK::CLI::ExitWithError, _('PDK does not support generating unit tests for "%{object_type}" objects.') % { object_type: e.message }
      end
    end
  end
end

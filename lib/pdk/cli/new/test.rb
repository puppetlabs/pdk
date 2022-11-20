module PDK::CLI
  @new_define_cmd = @new_cmd.define_command do
    name 'test'
    usage 'test [options] <name>'
    summary 'Create a new test for the object named <name>'
    flag :u, :unit, 'Create a new unit test.'
    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)

    run do |opts, args, _cmd|
      require 'pdk/util/puppet_strings'
      require 'pdk/util/bundler'

      PDK::CLI::Util.validate_puppet_version_opts(opts)
      PDK::CLI::Util.ensure_in_module!(
        message: 'Tests can only be created from inside a valid module directory.',
        log_level: :info,
      )

      object_name = args[0]

      if object_name.nil? || object_name.empty?
        puts command.help
        exit 1
      end

      unless opts[:unit]
        # At a future time, we'll replace this conditional with an interactive
        # question to choose the test type.
        PDK.logger.info 'Test type not specified, assuming unit.'
        opts[:unit] = true
      end

      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])
      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      begin
        generator, obj = PDK::Util::PuppetStrings.find_object(object_name)

        PDK::CLI::Util.analytics_screen_view('new_test', opts)

        updates = generator.new(PDK.context, obj['name'], opts.merge(spec_only: true)).run
        PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
      rescue PDK::Util::PuppetStrings::NoObjectError
        raise PDK::CLI::ExitWithError, 'Unable to find anything called "%{object}" to generate unit tests for.' % { object: object_name }
      rescue PDK::Util::PuppetStrings::NoGeneratorError => e
        raise PDK::CLI::ExitWithError, 'PDK does not support generating unit tests for "%{object_type}" objects.' % { object_type: e.message }
      end
    end
  end
end

module PDK::CLI
  @validate_cmd = @base_cmd.define_command do
    name 'validate'
    usage _('validate [validators] [options] [targets]')
    summary _('Run static analysis tests.')
    description _(
      "Run metadata, YAML, Puppet, Ruby, or Tasks validation.\n\n" \
      '[validators] is an optional comma-separated list of validators to use. ' \
      'If not specified, all validators are used. ' \
      "Note that when using PowerShell, the list of validators must be enclosed in single quotes.\n\n" \
      '[targets] is an optional space-separated list of files or directories to be validated. ' \
      'If not specified, validators are run against all applicable files in the module.',
    )

    PDK::CLI.puppet_version_options(self)
    PDK::CLI.puppet_dev_option(self)
    flag nil, :list, _('List all available validators.')
    flag :a, 'auto-correct', _('Automatically correct problems where possible.')
    flag nil, :parallel, _('Run validations in parallel.')

    run do |opts, args, _cmd|
      # Write the context information to the debug log
      PDK.context.to_debug_log

      if args == ['help']
        PDK::CLI.run(['validate', '--help'])
        exit 0
      end

      require 'pdk/validate'

      if opts[:list]
        PDK::CLI::Util.analytics_screen_view('validate', opts)
        PDK.logger.info(_('Available validators: %{validator_names}') % { validator_names: PDK::Validate.validator_names.join(', ') })
        exit 0
      end

      PDK::CLI::Util.validate_puppet_version_opts(opts)

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Code validation can only be run from inside a valid module directory'),
        log_level: :info,
      )

      PDK::CLI::Util.module_version_check

      targets = []
      validators_to_run = nil
      if args[0]
        # This may be a single validator, a list of validators, or a target.
        if Util::OptionValidator.comma_separated_list?(args[0])
          # This is a comma separated list. Treat each item as a validator.
          vals = Util::OptionNormalizer.comma_separated_list_to_array(args[0])
          validators_to_run = PDK::Validate.validator_names.select { |name| vals.include?(name) }

          vals.reject { |v| PDK::Validate.validator_names.include?(v) }
              .each do |v|
            PDK.logger.warn(_("Unknown validator '%{v}'. Available validators: %{validators}.") % { v: v, validators: PDK::Validate.validator_names.join(', ') })
          end
        else
          # This is a single item. Check if it's a known validator, or otherwise treat it as a target.
          val = PDK::Validate.validator_names.find { |name| args[0] == name }
          if val
            validators_to_run = [val]
          else
            targets = [args[0]]
            # We now know that no validators were passed, so let the user know we're using all of them by default.
            PDK.logger.info(_('Running all available validators...'))
          end
        end
      else
        PDK.logger.info(_('Running all available validators...'))
      end
      validators_to_run = PDK::Validate.validator_names if validators_to_run.nil?

      if validators_to_run.sort == PDK::Validate.validator_names.sort
        PDK::CLI::Util.analytics_screen_view('validate', opts)
      else
        PDK::CLI::Util.analytics_screen_view(['validate', validators_to_run.sort].flatten.join('_'), opts)
      end

      # Subsequent arguments are targets.
      targets.concat(args.to_a[1..-1]) if args.length > 1

      report = PDK::Report.new
      report_formats = if opts[:format]
                         PDK::CLI::Util::OptionNormalizer.report_formats(opts[:format])
                       else
                         [{
                           method: PDK::Report.default_format,
                           target: PDK::Report.default_target,
                         }]
                       end

      options = targets.empty? ? {} : { targets: targets }
      options[:auto_correct] = true if opts[:'auto-correct']

      # Ensure that the bundled gems are up to date and correct Ruby is activated before running any validations.
      puppet_env = PDK::CLI::Util.puppet_from_opts_or_env(opts)
      PDK::Util::RubyVersion.use(puppet_env[:ruby_version])

      options.merge!(puppet_env[:gemset])

      require 'pdk/util/bundler'

      PDK::Util::Bundler.ensure_bundle!(puppet_env[:gemset])

      exit_code, report = PDK::Validate.invoke_validators_by_name(PDK.context, validators_to_run, opts.fetch(:parallel, false), options)

      report_formats.each do |format|
        report.send(format[:method], format[:target])
      end

      exit exit_code
    end
  end
end

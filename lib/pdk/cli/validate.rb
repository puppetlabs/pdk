require 'pdk/util/bundler'

module PDK::CLI
  @validate_cmd = @base_cmd.define_command do
    name 'validate'
    usage _('validate [validators] [options] [targets]')
    summary _('Run static analysis tests.')
    description _(
      "Run metadata, puppet, or ruby validation.\n\n" \
      '[validators] is an optional comma separated list of validators to use. ' \
      "If not specified, all validators will be used.\n\n" \
      '[targets] is an optional space separated list of files or directories to be validated. ' \
      'If not specified, the validators will be run against all applicable files in the module.',
    )

    flag nil, :list, _('list all available validators')
    flag :a, 'auto-correct', _('automatically correct problems (where possible)')
    flag nil, :parallel, _('run validations in parallel')

    run do |opts, args, _cmd|
      if args == ['help']
        PDK::CLI.run(['validate', '--help'])
        exit 0
      end

      validator_names = PDK::Validate.validators.map { |v| v.name }
      validators = PDK::Validate.validators
      targets = []

      if opts[:list]
        PDK.logger.info(_('Available validators: %{validator_names}') % { validator_names: validator_names.join(', ') })
        exit 0
      end

      PDK::CLI::Util.ensure_in_module!

      if args[0]
        # This may be a single validator, a list of validators, or a target.
        if Util::OptionValidator.comma_separated_list?(args[0])
          # This is a comma separated list. Treat each item as a validator.

          vals = Util::OptionNormalizer.comma_separated_list_to_array(args[0])
          validators = PDK::Validate.validators.select { |v| vals.include?(v.name) }

          invalid = vals.reject { |v| validator_names.include?(v) }
          invalid.each do |v|
            PDK.logger.warn(_("Unknown validator '%{v}'. Available validators: %{validators}") % { v: v, validators: validator_names.join(', ') })
          end
        else
          # This is a single item. Check if it's a known validator, or otherwise treat it as a target.
          val = PDK::Validate.validators.find { |v| args[0] == v.name }
          if val
            validators = [val]
          else
            targets = [args[0]]
            # We now know that no validators were passed, so let the user know we're using all of them by default.
            PDK.logger.info(_('Running all available validators...'))
          end
        end
      else
        PDK.logger.info(_('Running all available validators...'))
      end

      # Subsequent arguments are targets.
      targets.concat(args[1..-1]) if args.length > 1

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
      options[:auto_correct] = true if opts.key?(:'auto-correct')

      # Ensure that the bundle is installed and tools are available before running any validations.
      PDK::Util::Bundler.ensure_bundle!

      exit_code = 0
      if opts[:parallel]
        exec_group = PDK::CLI::ExecGroup.new(_('Validating module using %{num_of_threads} threads' % { num_of_threads: validators.count }), opts)

        validators.each do |validator|
          exec_group.register do
            validator.invoke(report, options.merge(exec_group: exec_group))
          end
        end

        exit_code = exec_group.exit_code
      else
        validators.each do |validator|
          validator_exit_code = validator.invoke(report, options.dup)
          exit_code = validator_exit_code if validator_exit_code != 0
        end
      end

      report_formats.each do |format|
        report.send(format[:method], format[:target])
      end

      exit exit_code
    end
  end
end

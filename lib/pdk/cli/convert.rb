module PDK::CLI
  @convert_cmd = @base_cmd.define_command do
    name 'convert'
    usage _('convert [options]')
    summary _('Convert an existing module to be compatible with the PDK.')

    PDK::CLI.template_url_option(self)
    PDK::CLI.template_ref_option(self)
    PDK::CLI.skip_interview_option(self)
    PDK::CLI.full_interview_option(self)
    flag nil, :noop, _('Do not convert the module, just output what would be done.')
    flag nil, :force, _('Convert the module automatically, with no prompts.')
    flag nil, :'add-tests', _('Add any missing tests while converting the module.')
    flag nil, :'default-template', _('Convert the module to use the default PDK template.')

    run do |opts, _args, _cmd|
      require 'pdk/module/convert'
      require 'pdk/cli/util'

      PDK::CLI::Util.ensure_in_module!(
        check_module_layout: true,
        message:             _('`pdk convert` can only be run from inside a valid module directory.'),
        log_level:           :info,
      )

      if opts[:noop] && opts[:force]
        raise PDK::CLI::ExitWithError, _('You can not specify --noop and --force when converting a module')
      end

      if opts[:'default-template']
        raise PDK::CLI::ExitWithError, _('You can not specify --template-url and --default-template.') if opts[:'template-url']

        opts[:'template-url'] = PDK::Util::TemplateURI.default_template_addressable_uri.to_s
        PDK.answers.update!('template-url' => nil)
      end

      PDK::CLI::Util.validate_template_opts(opts)

      PDK::CLI::Util.analytics_screen_view('convert', opts)

      if opts[:'skip-interview'] && opts[:'full-interview']
        PDK.logger.info _('Ignoring --full-interview and continuing with --skip-interview.')
        opts[:'full-interview'] = false
      end

      if opts[:force] && opts[:'full-interview']
        PDK.logger.info _('Ignoring --full-interview and continuing with --force.')
        opts[:'full-interview'] = false
      end

      PDK::Module::Convert.invoke(PDK::Util.module_root, opts)
    end
  end
end

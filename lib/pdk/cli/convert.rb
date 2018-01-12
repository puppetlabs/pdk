require 'pdk/cli/util'

module PDK::CLI
  @convert_cmd = @base_cmd.define_command do
    name 'convert'
    usage _('convert [options]')
    summary _('Convert an existing module to be compatible with the PDK.')

    PDK::CLI.template_url_option(self)
    PDK::CLI.skip_interview_option(self)
    flag nil, :noop, _('Do not convert the module, just output what would be done.')
    flag nil, :force, _('Convert the module automatically, with no prompts.')

    run do |opts, _args, _cmd|
      require 'pdk/module/convert'

      PDK::CLI::Util.ensure_in_module!(
        check_module_layout: true,
        message:             _('`pdk convert` can only be run from inside a valid module directory.'),
        log_level:           :info,
      )

      if opts[:noop] && opts[:force]
        raise PDK::CLI::ExitWithError, _('You can not specify --noop and --force when converting a module')
      end

      PDK::Module::Convert.invoke(opts)
    end
  end
end

require 'pdk/cli/util'

module PDK::CLI
  @convert_cmd = @base_cmd.define_command do
    name 'convert'
    usage _('convert [options]')
    summary _('Convert an existing module to be compatible with the PDK.')
    be_hidden

    PDK::CLI.template_url_option(self)
    flag nil, :noop, _('Do not convert the module, just output what would be done.')
    flag nil, :force, _('Convert the module automatically, with no prompts.')

    run do |opts, _args, _cmd|
      require 'pdk/module/convert'
      PDK::CLI::Util.ensure_in_module!

      if opts[:noop] && opts[:force]
        raise PDK::CLI::ExitWithError, _('You can not specify --noop and --force when converting a module')
      end

      unless opts[:noop] || opts[:force]
        PDK.logger.info _('This is a potentially destructive action. Please ensure that you have committed it to a version control system or have a backup before continuing.')
        exit 0 unless PDK::CLI::Util.prompt_for_yes(_('Do you want to continue converting this module?'))
      end

      PDK::Module::Convert.invoke(opts)
    end
  end
end

require 'tty-prompt'

module PDK::CLI
  @module_generate_cmd = @module_cmd.define_command do
    name 'generate'
    usage _('generate [options] <module_name>')
    summary _('This command is now \'pdk new module\'.')
    be_hidden

    PDK::CLI.template_url_option(self)
    PDK::CLI.skip_interview_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generators/module'

      module_name = args[0]

      if module_name.nil? || module_name.empty?
        puts command.help
        exit 1
      end

      PDK.logger.info(_('New modules are created using the ‘pdk new module’ command.'))
      prompt = TTY::Prompt.new(help_color: :cyan)
      redirect = PDK::CLI::Util::CommandRedirector.new(prompt)
      redirect.target_command('pdk new module')
      answer = redirect.run

      if answer
        opts[:module_name] = module_name
        opts[:target_dir] = module_name

        PDK.logger.info(_('Creating new module: %{modname}') % { modname: module_name })
        PDK::Generate::Module.invoke(opts)
      else
        exit 1
      end
    end
  end
end

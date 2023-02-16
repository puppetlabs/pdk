module PDK::CLI
  @module_generate_cmd = @module_cmd.define_command do
    name 'generate'
    usage 'generate [options] <module_name>'
    summary 'This command is now \'pdk new module\'.'

    PDK::CLI.template_url_option(self)
    PDK::CLI.template_ref_option(self)
    PDK::CLI.skip_interview_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generate/module'
      require 'tty/prompt'

      module_name = args[0]

      if module_name.nil? || module_name.empty?
        puts command.help
        exit 1
      end

      PDK::CLI::Util.validate_template_opts(opts)

      PDK.logger.info("New modules are created using the 'pdk new module' command.")
      prompt = TTY::Prompt.new(help_color: :cyan)
      redirect = PDK::CLI::Util::CommandRedirector.new(prompt)
      redirect.target_command('pdk new module')
      answer = redirect.run

      if answer
        module_name_parts = module_name.split('-', 2)
        if module_name_parts.size > 1
          opts[:username] = module_name_parts[0]
          opts[:module_name] = module_name_parts[1]
        else
          opts[:module_name] = module_name
        end
        opts[:target_dir] = opts[:module_name]

        PDK.logger.info('Creating new module: %{modname}' % { modname: module_name })
        PDK::Generate::Module.invoke(opts)
      else
        exit 1
      end
    end
  end
end

module PDK::CLI
  @new_module_cmd = @new_cmd.define_command do
    name 'module'
    usage 'module [options] [module_name] [target_dir]'
    summary 'Create a new module named [module_name] using given options'

    PDK::CLI.template_url_option(self)
    PDK::CLI.template_ref_option(self)
    PDK::CLI.skip_interview_option(self)
    PDK::CLI.full_interview_option(self)

    option nil, 'license', 'Specifies the license this module is written under. ' \
      "This should be a identifier from https://spdx.org/licenses/. Common values are 'Apache-2.0', 'MIT', or 'proprietary'.", argument: :required
    option nil, 'skip-bundle-install', 'Do not automatically run `bundle install` after creating the module.', hidden: true

    run do |opts, args, _cmd|
      require 'pdk/generate/module'

      module_name = args[0]
      target_dir = args[1]

      PDK::CLI::Util.validate_template_opts(opts)

      PDK::CLI::Util.analytics_screen_view('new_module', opts)

      if opts[:'skip-interview'] && opts[:'full-interview']
        PDK.logger.info 'Ignoring --full-interview and continuing with --skip-interview.'
        opts[:'full-interview'] = false
      end

      if module_name.nil? || module_name.empty?
        if opts[:'skip-interview']
          raise PDK::CLI::ExitWithError,
                'You must specify a module name on the command line when running ' \
                'with --skip-interview.'
        end
      else
        module_name_parts = module_name.split('-', 2)
        if module_name_parts.size > 1
          opts[:username] = module_name_parts[0]
          opts[:module_name] = module_name_parts[1]
        else
          opts[:module_name] = module_name
        end
        opts[:target_dir] = target_dir.nil? ? opts[:module_name] : target_dir
      end

      PDK.logger.info('Creating new module: %{modname}' % { modname: module_name })
      PDK::Generate::Module.invoke(opts)
    end
  end
end

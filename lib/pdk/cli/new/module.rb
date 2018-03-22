# frozen_string_literal: true

module PDK::CLI
  @new_module_cmd = @new_cmd.define_command do
    name 'module'
    usage _('module [options] [module_name] [target_dir]')
    summary _('Create a new module named [module_name] using given options')

    PDK::CLI.template_url_option(self)
    PDK::CLI.skip_interview_option(self)
    PDK::CLI.full_interview_option(self)

    option nil, 'license', _('Specifies the license this module is written under. ' \
      "This should be a identifier from https://spdx.org/licenses/. Common values are 'Apache-2.0', 'MIT', or 'proprietary'."), argument: :required

    run do |opts, args, _cmd|
      require 'pdk/generate/module'

      module_name = args[0]
      target_dir = args[1]

      if opts[:'skip-interview'] && opts[:'full-interview']
        PDK.logger.info _('Ignoring --full-interview and continuing with --skip-interview.')
        opts[:'full-interview'] = false
      end

      unless module_name.nil? || module_name.empty?
        module_name_parts = module_name.split('-', 2)
        if module_name_parts.size > 1
          opts[:username] = module_name_parts[0]
          opts[:module_name] = module_name_parts[1]
        else
          opts[:module_name] = module_name
        end
        opts[:target_dir] = target_dir.nil? ? opts[:module_name] : target_dir
      end

      PDK.logger.info(_('Creating new module: %{modname}') % { modname: module_name })
      PDK::Generate::Module.invoke(opts)
    end
  end
end

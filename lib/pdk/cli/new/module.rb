module PDK::CLI
  @new_module_cmd = @new_cmd.define_command do
    name 'module'
    usage _('module [options] <module_name> [target_dir]')
    summary _('Create a new module named <module_name> using given options')

    PDK::CLI.template_url_option(self)
    PDK::CLI.skip_interview_option(self)

    option nil, 'license', _('Specifies the license this module is written under. ' \
      "This should be a identifier from https://spdx.org/licenses/. Common values are 'Apache-2.0', 'MIT', or 'proprietary'."), argument: :required

    run do |opts, args, _cmd|
      require 'pdk/generators/module'

      module_name = args[0]
      target_dir = args[1]

      if module_name.nil? || module_name.empty?
        puts command.help
        exit 1
      end

      opts[:module_name] = module_name
      opts[:target_dir] = target_dir.nil? ? module_name : target_dir

      PDK.logger.info(_('Creating new module: %{modname}') % { modname: module_name })
      PDK::Generate::Module.invoke(opts)
    end
  end
end

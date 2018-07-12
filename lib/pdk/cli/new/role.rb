module PDK::CLI
  @new_role_cmd = @new_cmd.define_command do
    name 'role'
    usage _('role [options] <role_name>')
    summary _('Create a new role named <role_name> using given options')

    PDK::CLI.template_url_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generate/role'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Classes can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      role_name = args[0]
      module_dir = Dir.pwd

      if role_name.nil? || role_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(role_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid role name") % { name: role_name }
      end

      PDK::Generate::Role.new(module_dir, role_name, opts).run
    end
  end
end

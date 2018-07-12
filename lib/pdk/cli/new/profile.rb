module PDK::CLI
  @new_profile_cmd = @new_cmd.define_command do
    name 'profile'
    usage _('profile [options] <profile_name>')
    summary _('Create a new profile named <profile_name> using given options')

    PDK::CLI.template_url_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generate/profile'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Classes can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      profile_name = args[0]
      module_dir = Dir.pwd

      if profile_name.nil? || profile_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(profile_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid profile name") % { name: profile_name }
      end

      PDK::Generate::Profile.new(module_dir, profile_name, opts).run
    end
  end
end

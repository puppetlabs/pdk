module PDK::CLI
  @new_class_cmd = @new_cmd.define_command do
    name 'class'
    usage _('class [options] <class_name>')
    summary _('Create a new class named <class_name> using given options')

    run do |opts, args, _cmd|
      require 'pdk/generate/puppet_class'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Classes can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      class_name = args[0]

      if class_name.nil? || class_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(class_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid class name") % { name: class_name }
      end

      PDK::CLI::Util.analytics_screen_view('new_class', opts)

      PDK::Generate::PuppetClass.new(PDK::Util.module_root, class_name, opts).run
    end
  end
end

module PDK::CLI
  @new_class_cmd = @new_cmd.define_command do
    name 'class'
    usage 'class [options] <class_name>'
    summary 'Create a new class named <class_name> using given options'

    run do |opts, args, _cmd|
      require 'pdk/generate/puppet_class'

      PDK::CLI::Util.ensure_in_module!(
        message:   'Classes can only be created from inside a valid module directory.',
        log_level: :info,
      )

      class_name = args[0]

      if class_name.nil? || class_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(class_name)
        raise PDK::CLI::ExitWithError, "'%{name}' is not a valid class name" % { name: class_name }
      end

      PDK::CLI::Util.analytics_screen_view('new_class', opts)

      updates = PDK::Generate::PuppetClass.new(PDK.context, class_name, opts).run
      PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
    end
  end
end

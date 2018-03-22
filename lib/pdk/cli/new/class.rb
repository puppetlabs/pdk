# frozen_string_literal: true

module PDK::CLI
  @new_class_cmd = @new_cmd.define_command do
    name 'class'
    usage _('class [options] <class_name>')
    summary _('Create a new class named <class_name> using given options')

    PDK::CLI.template_url_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generate/puppet_class'

      PDK::CLI::Util.ensure_in_module!(
        message:   _('Classes can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      class_name = args[0]
      module_dir = Dir.pwd

      if class_name.nil? || class_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(class_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid class name") % { name: class_name }
      end

      PDK::Generate::PuppetClass.new(module_dir, class_name, opts).run
    end
  end
end

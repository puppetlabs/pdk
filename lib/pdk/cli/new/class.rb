
module PDK::CLI
  @new_class_cmd = @new_cmd.define_command do
    name 'class'
    usage _('class [options] <class_name> [parameter[:type]] [parameter[:type]] ...')
    summary _('Create a new class named <class_name> using given options')

    PDK::CLI.template_url_option(self)

    run do |opts, args, _cmd|
      require 'pdk/generators/puppet_class'

      class_name = args[0]
      module_dir = Dir.pwd

      if class_name.nil? || class_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_class_name?(class_name)
        raise PDK::CLI::FatalError, _("'%{name}' is not a valid class name") % { name: class_name }
      end

      if args.length > 1
        opts[:params] = args[1..-1].map { |r| Util::OptionNormalizer.parameter_specification(r) }
      end

      PDK::Generate::PuppetClass.new(module_dir, class_name, opts).run
    end
  end
end

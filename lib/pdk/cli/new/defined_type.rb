# frozen_string_literal: true

module PDK::CLI
  @new_define_cmd = @new_cmd.define_command do
    name 'defined_type'
    usage _('defined_type [options] <name>')
    summary _('Create a new defined type named <name> using given options')

    PDK::CLI.template_url_option(self)

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!(
        message: _('Defined types can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      defined_type_name = args[0]
      module_dir = Dir.pwd

      if defined_type_name.nil? || defined_type_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_defined_type_name?(defined_type_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid defined type name") % { name: defined_type_name }
      end

      PDK::Generate::DefinedType.new(module_dir, defined_type_name, opts).run
    end
  end
end

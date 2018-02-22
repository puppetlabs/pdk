module PDK::CLI
  @new_provider_cmd = @new_cmd.define_command do
    name 'provider'
    usage _('provider [options] <name>')
    summary _('[experimental] Create a new ruby provider named <name> using given options')

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      provider_name = args[0]
      module_dir = Dir.pwd

      if provider_name.nil? || provider_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_provider_name?(provider_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid provider name") % { name: provider_name }
      end

      PDK::Generate::Provider.new(module_dir, provider_name, opts).run
    end
  end
end

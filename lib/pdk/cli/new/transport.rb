module PDK::CLI
  @new_transport_cmd = @new_cmd.define_command do
    name 'transport'
    usage _('transport [options] <name>')
    summary _('[experimental] Create a new ruby transport named <name> using given options')

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      transport_name = args[0]

      if transport_name.nil? || transport_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_transport_name?(transport_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid transport name") % { name: transport_name }
      end

      require 'pdk/generate/transport'

      PDK::Generate::Transport.new(PDK::Util.module_root, transport_name, opts).run
    end
  end
end

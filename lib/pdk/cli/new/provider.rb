module PDK::CLI
  @new_provider_cmd = @new_cmd.define_command do
    name 'provider'
    usage 'provider [options] <name>'
    summary '[experimental] Create a new ruby provider named <name> using given options'

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      provider_name = args[0]

      if provider_name.nil? || provider_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_provider_name?(provider_name)
        raise PDK::CLI::ExitWithError, "'%{name}' is not a valid provider name" % { name: provider_name }
      end

      PDK::CLI::Util.analytics_screen_view('new_provider', opts)

      require 'pdk/generate/provider'

      updates = PDK::Generate::Provider.new(PDK.context, provider_name, opts).run
      PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
    end
  end
end

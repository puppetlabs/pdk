module PDK::CLI
  @new_fact_cmd = @new_cmd.define_command do
    name 'fact'
    usage 'fact [options] <name>'
    summary 'Create a new custom fact named <name> using given options'

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      fact_name = args[0]

      if fact_name.nil? || fact_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_fact_name?(fact_name)
        raise PDK::CLI::ExitWithError, "'%{name}' is not a valid fact name" % { name: fact_name }
      end

      PDK::CLI::Util.analytics_screen_view('new_fact', opts)

      require 'pdk/generate/fact'

      updates = PDK::Generate::Fact.new(PDK.context, fact_name, opts).run
      PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
    end
  end
end

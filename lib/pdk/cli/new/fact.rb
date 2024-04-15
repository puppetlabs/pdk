module PDK
  module CLI
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

        raise PDK::CLI::ExitWithError, format("'%{name}' is not a valid fact name", name: fact_name) unless Util::OptionValidator.valid_fact_name?(fact_name)

        require 'pdk/generate/fact'

        updates = PDK::Generate::Fact.new(PDK.context, fact_name, opts).run
        PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
      end
    end
  end
end

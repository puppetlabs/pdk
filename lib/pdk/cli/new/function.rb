module PDK::CLI
  @new_function_cmd = @new_cmd.define_command do
    name 'function'
    usage 'function [options] <name>'
    summary 'Create a new function named <name> using given options'
    option :t, :type, 'The function type, (native or v4)', argument: :required, default: 'native'

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      function_name = args[0]

      if function_name.nil? || function_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_function_name?(function_name)
        raise PDK::CLI::ExitWithError, "'%{name}' is not a valid function name" % { name: function_name }
      end

      PDK::CLI::Util.analytics_screen_view('new_function', opts)

      require 'pdk/generate/function'
      updates = PDK::Generate::Function.new(PDK.context, function_name, opts).run
      PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
    end
  end
end

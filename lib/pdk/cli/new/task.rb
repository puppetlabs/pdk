module PDK
  module CLI
    @new_task_cmd = @new_cmd.define_command do
      name 'task'
      usage 'task [options] <name>'
      summary 'Create a new task named <name> using given options'

      option nil, :description, 'A short description of the purpose of the task', argument: :required

      run do |opts, args, _cmd|
        require 'pdk/generate/task'

        PDK::CLI::Util.ensure_in_module!(
          message: 'Tasks can only be created from inside a valid module directory.',
          log_level: :info
        )

        task_name = args[0]

        if task_name.nil? || task_name.empty?
          puts command.help
          exit 1
        end

        raise PDK::CLI::ExitWithError, format("'%{name}' is not a valid task name", name: task_name) unless Util::OptionValidator.valid_task_name?(task_name)

        PDK::CLI::Util.analytics_screen_view('new_task', opts)

        updates = PDK::Generate::Task.new(PDK.context, task_name, opts).run
        PDK::CLI::Util::UpdateManagerPrinter.print_summary(updates, tense: :past)
      end
    end
  end
end

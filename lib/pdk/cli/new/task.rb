# frozen_string_literal: true

module PDK::CLI
  @new_task_cmd = @new_cmd.define_command do
    name 'task'
    usage _('task [options] <name>')
    summary _('Create a new task named <name> using given options')

    PDK::CLI.template_url_option(self)
    option nil, :description, _('A short description of the purpose of the task'), argument: :required

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!(
        message:   _('Tasks can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      task_name = args[0]
      module_dir = Dir.pwd

      if task_name.nil? || task_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_task_name?(task_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid task name") % { name: task_name }
      end

      PDK::Generate::Task.new(module_dir, task_name, opts).run
    end
  end
end

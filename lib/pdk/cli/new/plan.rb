module PDK::CLI
  @new_plan_cmd = @new_cmd.define_command do
    name 'plan'
    usage _('plan [options] <name>')
    summary _('Create a new plan named <name> using given options')

    PDK::CLI.template_url_option(self)
    option nil, :description, _('A short description of the purpose of the plan'), argument: :required

    run do |opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!(
        message:   _('plans can only be created from inside a valid module directory.'),
        log_level: :info,
      )

      plan_name = args[0]
      module_dir = Dir.pwd

      if plan_name.nil? || plan_name.empty?
        puts command.help
        exit 1
      end

      unless Util::OptionValidator.valid_plan_name?(plan_name)
        raise PDK::CLI::ExitWithError, _("'%{name}' is not a valid plan name") % { name: plan_name }
      end

      PDK::Generate::Plan.new(module_dir, plan_name, opts).run
    end
  end
end

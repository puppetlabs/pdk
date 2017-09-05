module PDK::CLI
  @module_cmd = @base_cmd.define_command do
    name 'module'
    usage _('module [options]')
    summary _('Perform administrative tasks on your module.')
    description _('Perform tasks on the module project.')
    default_subcommand 'help'
    be_hidden
  end

  @module_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/module/generate'

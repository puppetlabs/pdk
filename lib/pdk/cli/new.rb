
module PDK::CLI
  @new_cmd = @base_cmd.define_command do
    name 'new'
    usage _('new <type> [options]')
    summary _('create a new module, etc.')
    description _('Creates a new instance of <type> using the options relevant to that type of thing')
    default_subcommand 'help'
  end

  @new_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/new/class'
require 'pdk/cli/new/module'

module PDK::CLI
  @new_cmd = @base_cmd.define_command do
    name 'new'
    usage _('new <thing> [options]')
    summary _('create a new module, etc.')
    description _('Creates a new <thing> using relevant options.')
    default_subcommand 'help'
  end

  @new_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/new/class'
require 'pdk/cli/new/defined_type'
require 'pdk/cli/new/module'
require 'pdk/cli/new/provider'
require 'pdk/cli/new/task'
require 'pdk/cli/new/transport'
require 'pdk/cli/new/unit_test'

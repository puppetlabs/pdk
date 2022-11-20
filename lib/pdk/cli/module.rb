module PDK::CLI
  @module_cmd = @base_cmd.define_command do
    name 'module'
    usage 'module [options]'
    summary 'Provide CLI-backwards compatibility to the puppet module tool.'
    description 'This command is only for reminding you how to accomplish tasks with the PDK, when you were previously doing them with the puppet module command.'
    default_subcommand 'help'
  end

  @module_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/module/build'
require 'pdk/cli/module/generate'

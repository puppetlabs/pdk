module PDK::CLI
  @test_cmd = @base_cmd.define_command do
    name 'test'
    usage 'test [subcommand] [options]'
    summary 'Run tests.'
    default_subcommand 'help'
  end
  @test_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/test/unit'

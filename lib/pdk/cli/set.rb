module PDK::CLI
  @set_cmd = @base_cmd.define_command do
    name 'set'
    usage 'set [subcommand] [options]'
    summary 'Set or update information about the PDK or current project.'
    default_subcommand 'help'

    run do |_opts, args, _cmd|
      if args == ['help']
        PDK::CLI.run(%w[set --help])
        exit 0
      end

      PDK::CLI.run(%w[set help]) if args.empty?
    end
  end
  @set_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/set/config'

module PDK::CLI
  @remove_cmd = @base_cmd.define_command do
    name 'remove'
    usage 'remove [subcommand] [options]'
    summary 'Remove or delete information about the PDK or current project.'
    default_subcommand 'help'

    run do |_opts, args, _cmd|
      if args == ['help']
        PDK::CLI.run(%w[remove --help])
        exit 0
      end

      PDK::CLI.run(%w[remove help]) if args.empty?
    end
  end
  @remove_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/remove/config'

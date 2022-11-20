module PDK::CLI
  @get_cmd = @base_cmd.define_command do
    name 'get'
    usage 'get [subcommand] [options]'
    summary 'Retrieve information about the PDK or current project.'
    default_subcommand 'help'

    run do |_opts, args, _cmd|
      if args == ['help']
        PDK::CLI.run(%w[get --help])
        exit 0
      end

      PDK::CLI.run(%w[get help]) if args.empty?
    end
  end
  @get_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/get/config'

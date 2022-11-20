module PDK::CLI
  @config_cmd = @base_cmd.define_command do
    name 'config'
    usage 'config [subcommand] [options]'
    summary '(Deprecated) Configure the Puppet Development Kit.'
    default_subcommand 'help'

    run do |_opts, args, _cmd|
      PDK.logger.warn 'The \'pdk config\' command is deprecated, please use \'pdk get config\' and \'pdk set config\' instead.'

      if args == ['help']
        PDK::CLI.run(%w[config --help])
        exit 0
      end

      PDK::CLI.run(%w[config help]) if args.empty?
    end
  end
  @config_cmd.add_command Cri::Command.new_basic_help
end

require 'pdk/cli/config/get'

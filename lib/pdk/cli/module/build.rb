module PDK::CLI
  @module_build_cmd = @module_cmd.define_command do
    name 'build'
    usage 'build'
    summary 'This command is now \'pdk build\'.'

    run do |_opts, _args, _cmd|
      PDK.logger.warn("Modules are built using the 'pdk build' command.")
      exit 1
    end
  end
end

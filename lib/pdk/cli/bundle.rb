
module PDK::CLI
  @bundle_cmd = @base_cmd.define_command do
    name 'bundle'
    usage _('bundle -- [bundler_options]')
    summary _('escape hatch to bundler')
    description _('[experimental] For advanced users, this allows to run arbitrary commands in the bundler environment that the pdk manages. ' \
      'Careless use of this command can lead to errors later which can\'t be recovered by the pdk itself.')

    run do |_opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!

      command = PDK::CLI::Exec::Command.new(PDK::CLI::Exec.bundle_bin, *args).tap do |c|
        c.context = :module
      end

      result = command.execute!

      $stderr.puts result[:stdout]
      $stderr.puts result[:stderr]

      exit result[:exit_code]
    end
  end
end

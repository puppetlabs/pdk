
module PDK::CLI
  @bundle_cmd = @base_cmd.define_command do
    name 'bundle'
    usage _('bundle -- [bundler_options]')
    summary _('(Experimental) Command pass-through to bundler')
    description _('[experimental] For advanced users, pdk bundle runs arbitrary commands in the bundler environment that pdk manages.' \
      'Careless use of this command can lead to errors that pdk can\'t help recover from.')

    be_hidden

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

# frozen_string_literal: true

module PDK::CLI
  @bundle_cmd = @base_cmd.define_command do
    name 'bundle'
    if Gem.win_platform?
      usage _('bundle `-- [bundler_options]')
    else
      usage _('bundle -- [bundler_options]')
    end
    summary _('(Experimental) Command pass-through to bundler')
    description _(<<-EOF
[experimental] For advanced users, pdk bundle runs arbitrary commands in the bundler environment that pdk manages.
Careless use of this command can lead to errors that pdk can't help recover from.

Note that for PowerShell the '--' needs to be escaped using a backtick: '`--' to avoid it being parsed by the shell.
EOF
                 )

    run do |_opts, args, _cmd|
      PDK::CLI::Util.ensure_in_module!(
        message: _('`pdk bundle` can only be run from inside a valid module directory.'),
      )

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

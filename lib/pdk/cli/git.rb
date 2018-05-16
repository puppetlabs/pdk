module PDK::CLI
  @git_cmd = @base_cmd.define_command do
    name 'git'
    usage _('git [git_options]')
    summary _('(experimental) Runs the bundled git using given options')
    skip_option_parsing

    run do |_opts, args, _cmd|
      result = PDK::CLI::Exec.git(*args)

      output = result[:stdout].strip + result[:stderr].strip
      $stderr.puts output unless output.empty?
    end
  end
end

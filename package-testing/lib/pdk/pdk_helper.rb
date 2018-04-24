def install_dir(host)
  if host.platform =~ %r{windows}
    '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit'
  else
    '/opt/puppetlabs/pdk'
  end
end

def pdk_git_bin_dir(host)
  if host.platform =~ %r{windows}
    "#{install_dir(host)}/private/git/mingw64/bin"
  else
    "#{install_dir(host)}/private/git/bin"
  end
end

# Common way to just invoke 'pdk' on each platform
def pdk_command(host, command, env = {})
  env ||= {}
  env_str = ''

  if host.platform =~ %r{windows}
    env.each do |var, val|
      env_str += "\\$env:#{var}='#{val}'; "
    end

    # Pass the command to powershell and exit powershell with pdk's exit code
    "powershell -Command \"#{env_str.tr('"', '\"').strip} pdk #{command.tr('"', '\"')}; exit $LASTEXITCODE\""
  else
    env.each do |var, val|
      env_str += "#{var}=#{val} "
    end

    "/bin/bash -lc \"#{env_str} pdk #{command}\""
  end
end

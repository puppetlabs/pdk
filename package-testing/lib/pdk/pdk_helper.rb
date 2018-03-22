# frozen_string_literal: true

def install_dir(host)
  if host.platform.match?(%r{windows})
    '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit'
  else
    '/opt/puppetlabs/pdk'
  end
end

def pdk_git_bin_dir(host)
  if host.platform.match?(%r{windows})
    "#{install_dir(host)}/private/git/mingw64/bin"
  else
    "#{install_dir(host)}/private/git/bin"
  end
end

# Common way to just invoke 'pdk' on each platform
def pdk_command(host, command)
  if host.platform.match?(%r{windows})
    # Pass the command to powershell and exit powershell with pdk's exit code
    "powershell -Command 'pdk #{command.tr("'", "\'")}; exit $LASTEXITCODE'"
  else
    "/bin/bash -lc \"pdk #{command}\""
  end
end

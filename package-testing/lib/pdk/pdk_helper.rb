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
def pdk_command(host, command)
  if host.platform =~ %r{windows}
    "powershell pdk #{command}"
  else
    "pdk #{command}"
  end
end

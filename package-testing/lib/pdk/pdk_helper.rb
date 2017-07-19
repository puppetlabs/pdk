# Memoized working directory to run the tests from

# NOTE: currently there is an issue with beaker's create_tmpdir_on helper on cygwin
# and OSX platforms:  the `chown` command always fails with an error about not
# recognizing the Administrator:Administrator user/group.  Also, the call to
# check user presence via `getent` also fails. Until this is fixed, we add this
# shim that delegates to a non-`chown`/non-`getent`-executing version for the
# purposes of our test setup.
#
# TODO: fix via: https://tickets.puppetlabs.com/browse/BKR-496
def tmpdir_on(hosts, path_prefix = '', user = nil)
  first_host = Array(hosts).first

  return create_tmpdir_on(hosts, path_prefix, user) unless \
    first_host.is_cygwin? || first_host.platform =~ %r{osx}

  block_on hosts do |host|
    # use default user logged into this host
    unless user
      user = host['user']
    end

    raise 'Host platform not supported by `tmpdir_on`.' unless defined? host.tmpdir
    host.tmpdir(path_prefix)
  end
end

def target_dir
  $target_dir ||= tmpdir_on(workstation, 'pdk_acceptance') # rubocop:disable Style/GlobalVars
end

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

def pdk_rubygems_cert_dir(host)
  "#{install_dir(host)}/private/ruby/2.1.9/lib/ruby/2.1.0/rubygems/ssl_certs"
end

def command_prefix(host)
  command = "PATH=#{install_dir(host)}/bin:#{install_dir(host)}/private/ruby/2.1.9/bin:#{pdk_git_bin_dir(host)}:$PATH && cd #{target_dir} &&"
  command = "#{command} cmd.exe /C" unless host.platform !~ %r{windows}
  command
end

def run_rspec(host)
  command = "PATH=#{install_dir(host)}/bin:#{pdk_git_bin_dir(host)}:$PATH && cd #{target_dir} &&"
  if host.platform =~ %r{windows}
    command = "#{command} cmd.exe /C \"C://Program Files/Puppet Labs/DevelopmentKit/private/ruby/2.1.9/bin/rspec\""
  else
    command = "#{command} /opt/puppetlabs/pdk/private/ruby/2.1.9/bin/rspec"
  end
  command
end

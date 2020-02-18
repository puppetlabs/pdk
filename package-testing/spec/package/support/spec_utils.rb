module SpecUtils
  def install_dir(cygpath = false)
    if windows_node?
      if cygpath
        '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit'
      else
        'C:/Program Files/Puppet Labs/DevelopmentKit'
      end
    else
      '/opt/puppetlabs/pdk'
    end
  end

  def home_dir(cygpath = false)
    if windows_node?
      cygpath ? '/home/Administrator' : 'c:/cygwin64/home/Administrator'
    else
      case get_working_node.platform
      when %r{\Aosx-10\.15-}
        '/var/root'
      else
        '/root'
      end
    end
  end

  def windows_node?
    get_working_node.platform =~ %r{windows}
  end
  module_function :windows_node?

  def git_bin
    path = File.join(install_dir, 'private', 'git')
    windows_node? ? "& '#{File.join(path, 'cmd', 'git.exe')}'" : File.join(path, 'bin', 'git')
  end

  def hosts_file
    if windows_node?
      '/cygdrive/c/Windows/System32/Drivers/etc/hosts'
    else
      '/etc/hosts'
    end
  end

  def ruby_cache_dir
    File.join(install_dir(true), 'private', 'ruby')
  end

  def latest_ruby
    installed_rubies = shell("cd #{ruby_cache_dir}; ls -dr *").stdout.split
    installed_rubies[0]
  end
end

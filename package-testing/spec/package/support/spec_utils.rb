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
    return '/root' unless windows_node?

    cygpath ? '/home/Administrator' : 'c:/cygwin64/home/Administrator'
  end

  def windows_node?
    get_working_node.platform =~ %r{windows}
  end
  module_function :windows_node?

  def git_bin
    path = File.join(install_dir, 'private', 'git')
    windows_node? ? "& '#{File.join(path, 'cmd', 'git.exe')}'" : File.join(path, 'bin', 'git')
  end
end

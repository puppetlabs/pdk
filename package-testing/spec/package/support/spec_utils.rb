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

  def windows_node?
    get_working_node.platform =~ %r{windows}
  end
  module_function :windows_node?
end

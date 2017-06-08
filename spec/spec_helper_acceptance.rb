require 'beaker/testmode_switcher/dsl'

if Beaker::TestmodeSwitcher.testmode == :local
  require 'serverspec'

  if Gem.win_platform?
    set :backend, :cmd
  else
    set :backend, :exec
  end

  # workaround pending release of https://github.com/puppetlabs/beaker-testmode_switcher/pull/13
  def hosts
    nil
  end
  def logger
    nil
  end
else
  require 'beaker-rspec'
end

def workstation
  find_at_most_one('workstation')
end

# Return the path to pdk executable.
# Returns the path to the binstub if executing locally
def path_to_pdk
  local_path = File.expand_path(File.join(__FILE__, '..', '..', 'bin', 'pdk'))
  posix_path = '/opt/puppetlabs/sdk/bin/pdk'
  windows_path = '/cygdrive/c/Program\ Files/Puppet\ Labs/DevelopmentKit/bin/pdk.bat'

  if Beaker::TestmodeSwitcher.testmode == :local
    return Gem.win_platform? ? "ruby #{local_path}" : local_path
  end

  if workstation['platform'] =~ /windows/
    windows_path
  else
    posix_path
  end
end

RSpec.configure do |c|
  c.before(:suite) do
    if Beaker::TestmodeSwitcher.testmode == :agent
      # Install pdk on workstation host
      if workstation['platform'] =~ /windows/
        # BKR-1109 requests a neater way to install an MSI
        msi_url = "http://#{ENV['BUILD_SERVER']}/puppet-sdk/#{ENV['SHA']}/repos/windows/puppet-sdk-x64.msi"
        generic_install_msi_on(workstation, msi_url)
      else
        install_puppetlabs_dev_repo(workstation, 'puppet-sdk', ENV['SHA'], 'repo-config')

        # Install pdk package
        workstation.install_package('puppet-sdk')
      end
    end
  end
end

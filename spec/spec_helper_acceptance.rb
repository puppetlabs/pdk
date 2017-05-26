require 'beaker-rspec'

def workstation
  find_at_most_one('workstation')
end

RSpec.configure do |c|
  c.before(:suite) do
    
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

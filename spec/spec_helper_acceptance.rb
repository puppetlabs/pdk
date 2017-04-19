require 'beaker-rspec'

def workstation
  find_at_most_one('workstation')
end

RSpec.configure do |c|
  c.before(:suite) do
    
    # Install pdk on workstation host
    install_puppetlabs_dev_repo(workstation, 'puppet-sdk', ENV['PACKAGE_BUILD_VERSION'], 'repo-config')

    # Install pdk package
    workstation.install_package('puppet-sdk')

  end
end

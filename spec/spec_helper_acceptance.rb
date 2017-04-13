require 'beaker-rspec'

RSpec.configure do |c|
  module_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  c.formatter = :documentation

  c.before :suite do
    
    workstation = find_at_most_one(workstation)
    # Install pdk on workstation host
    install_puppetlabs_dev_repo(workstation, 'puppet-sdk', ENV['PACKAGE_BUILD_VERSION'], 'repo-config')

    # Install pdk package
    workstation.install_package('puppet-sdk')

    # Add more setup code as needed
  end
end

test_name 'Install pdk package on workstation host' do
  workstation = find_at_most_one('workstation')

  step 'Install pdk package' do
    if ENV['LOCAL_PKG']
      pkg = File.basename(ENV['LOCAL_PKG'])
      scp_to(workstation, ENV['LOCAL_PKG'], pkg)
    end

    if workstation['platform'] =~ %r{windows}
      pkg ||= "http://#{ENV['BUILD_SERVER']}/pdk/#{ENV['SHA']}/repos/windows/pdk-x64.msi"

      # BKR-1109 requests a neater way to install an MSI
      generic_install_msi_on(workstation, pkg)
    else
      pkg ||= 'pdk'

      if ENV['SHA']
        install_puppetlabs_dev_repo(workstation, 'pdk', ENV['SHA'], 'repo-config')
      end

      workstation.install_package(pkg)
    end
  end
end

# frozen_string_literal: true

test_name 'Install pdk package on workstation host' do
  workstation = find_at_most_one('workstation')

  step 'Install pdk package' do
    if ENV['LOCAL_PKG']
      pkg = File.basename(ENV['LOCAL_PKG'])
      scp_to(workstation, ENV['LOCAL_PKG'], pkg)
    end

    case workstation['platform']
    # TODO: BKR-1109 requests a supported way to install packages on Windows and OSX
    when %r{windows}
      pkg ||= "http://#{ENV['BUILD_SERVER']}/pdk/#{ENV['SHA']}/artifacts/windows/pdk-#{ENV['SUITE_VERSION']}-x64.msi"
      generic_install_msi_on(workstation, pkg)
    when %r{osx}
      version, arch = workstation['platform'].split('-')[1, 2]
      pkg ||= "http://#{ENV['BUILD_SERVER']}/pdk/#{ENV['SHA']}/artifacts/apple/#{version}/PC1/#{arch}/pdk-#{ENV['SUITE_VERSION']}-1.osx#{version}.dmg"

      # The beaker helper for dmg needs to know the /Volumes folder name the dmg will mount to, and the pkg filename contained within that folder
      package_volume_name = "pdk-#{ENV['SUITE_VERSION']}"
      package_filename = "#{package_volume_name}-1-installer.pkg"

      logger.info("About to install '#{package_filename}' from '#{pkg}' on '#{workstation.hostname}'")
      workstation.generic_install_dmg(pkg, package_volume_name, package_filename)
    else
      # For most platforms, beaker will install the dev repo from the build server then 'install_package('pdk')' can simply be used
      pkg ||= 'pdk'

      if ENV['LOCAL_PKG']
        workstation.install_local_package(pkg)
      else
        install_puppetlabs_dev_repo(workstation, 'pdk', ENV['SHA'], 'repo-config')
        workstation.install_package(pkg)
      end
    end
  end
end

module PackageHelpers
  module_function

  def install_pdk_on(host)
    if local_package?
      install_local_pdk_package(host)
      return
    end

    case host.platform
    when %r{windows}
      install_windows_pdk_package(host)
    when %r{osx}
      install_osx_pdk_package(host)
    else
      install_dev_pdk_package(host)
    end
  end

  def local_package?
    ENV.key?('LOCAL_PKG')
  end

  def install_local_pdk_package(host)
    package = File.basename(ENV['LOCAL_PKG'])
    scp_to(host, ENV['LOCAL_PKG'], package)

    if host.platform =~ %r{windows}
      generic_install_msi_on(host, package)
    else
      host.install_local_package(package)
    end
  end

  def install_windows_pdk_package(host)
    generic_install_msi_on(host, build_artifact_url(host['platform']))
  end

  def install_osx_pdk_package(host)
    package_volume_name = "pdk-#{ENV['SUITE_VERSION']}"
    package_filename = "#{package_volume_name}-1-installer.pkg"
    host.generic_install_dmg(build_artifact_url(host.platform), package_volume_name, package_filename)
  end

  def install_dev_pdk_package(host)
    dev_builds_url = ENV['DEV_BUILDS_URL'] || 'http://builds.delivery.puppetlabs.net'
    sha_yaml_url = "#{dev_builds_url}/pdk/#{ENV['SHA']}/artifacts/#{ENV['SHA']}.yaml"

    install_from_build_data_url('pdk', sha_yaml_url)
    host.install_package('pdk')
  end

  def build_artifact_url(platform)
    url = "http://#{ENV['BUILD_SERVER']}/pdk/#{ENV['SHA']}/artifacts/"

    case platform
    when %r{windows}
      url += "windows/pdk-#{ENV['SUITE_VERSION']}-x64.msi"
    when %r{osx}
      version, arch = platform.split('-')[1, 2]
      url += "apple/#{version}/PC1/#{arch}/pdk-#{ENV['SUITE_VERSION']}-1.osx#{version}.dmg"
    else
      raise ArgumentError, "unknown platform #{platform}"
    end

    url
  end
end

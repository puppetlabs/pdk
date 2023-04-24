module PackageHelpers
  extend Beaker::DSL::InstallUtils::FOSSUtils
  extend Beaker::DSL::InstallUtils::Puppet5

  module_function

  def install_pdk_on(host)
    if local_package?
      install_local_pdk_package(host)
      return
    end

    case host.platform
    when /windows/
      install_windows_pdk_package(host)
    when /osx/
      install_osx_pdk_package(host)
    else
      install_dev_pdk_package(host)
    end
  end

  def local_package?
    ENV.key?('LOCAL_PKG')
  end

  def install_local_pdk_package(host)
    package = File.basename(ENV.fetch('LOCAL_PKG', nil))
    scp_to(host, ENV.fetch('LOCAL_PKG', nil), package)

    case host.platform
    when /windows/
      generic_install_msi_on(host, package)
    when /osx/
      package_volume_name = "pdk-#{ENV.fetch('SUITE_VERSION', nil)}"
      package_filename = "pdk-#{ENV.fetch('SUITE_VERSION', nil)}-1-installer.pkg"
      host.generic_install_dmg(package, package_volume_name, package_filename)
    else
      host.install_local_package(package)
    end
  end

  def install_windows_pdk_package(host)
    generic_install_msi_on(host, build_artifact_url(host['platform']))
  end

  def install_osx_pdk_package(host)
    version, = host.platform.split('-')[1, 2]
    package_volume_name = "pdk-#{ENV.fetch('SUITE_VERSION', nil)}-1.osx#{version}"
    package_filename = "pdk-#{ENV.fetch('SUITE_VERSION', nil)}-1-installer.pkg"
    host.generic_install_dmg(build_artifact_url(host.platform), package_volume_name, package_filename)
  end

  def install_dev_pdk_package(host)
    dev_builds_url = ENV.fetch('DEV_BUILDS_URL', nil) || 'http://builds.delivery.puppetlabs.net'
    sha_yaml_url = "#{dev_builds_url}/pdk/#{ENV.fetch('SHA', nil)}/artifacts/#{ENV.fetch('SHA', nil)}.yaml"

    install_from_build_data_url('pdk', sha_yaml_url)
    host.install_package('pdk')
  end

  def build_artifact_url(platform)
    url = "http://#{ENV.fetch('BUILD_SERVER', nil)}/pdk/#{ENV.fetch('SHA', nil)}/artifacts/"

    case platform
    when /windows/
      url += "windows/pdk-#{ENV.fetch('SUITE_VERSION', nil)}-x64.msi"
    when /osx/
      version, arch = platform.split('-')[1, 2]
      url += "osx/#{version}/#{arch}/pdk-#{ENV.fetch('SUITE_VERSION', nil)}-1.osx#{version}.dmg"
    else
      raise ArgumentError, "unknown platform #{platform}"
    end
    puts "Build_artifact_url: #{url}"
    url
  end
end

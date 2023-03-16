require 'spec_helper_package'

describe 'Using the PDK configuration commands' do
  def env_var(host, var_name)
    value = host.get_env_var(var_name)
    value.empty? ? nil : value[var_name.length + 1, value.length - var_name.length - 1]
  end

  def host_system_configdir(host)
    # This emulates the PDK::Util.system_configdir method
    # Ugh ... The double backslash escaping makes me sad :_(
    (host.platform =~ %r{windows}) ? 'C:\\\\ProgramData\\\\PuppetLabs\\\\PDK' : '/opt/puppetlabs/pdk/config'
  end

  def windows_path(path)
    # Why Beaker?!?! WHY!
    path.gsub('\\', '\\\\\\')
  end

  def host_user_configdir(host)
    # This emulates the PDK::Util.configdir method
    if %r{windows}.match?(host.platform)
      # Ugh... The double backslash escaping makes me REALLY sad :_(
      windows_path(env_var(host, 'LOCALAPPDATA')) + '\\\\PDK'
    else
      dir = env_var(host, 'XDG_CONFIG_HOME')
      dir.nil? ? env_var(host, 'HOME') + '/.config/pdk' : dir + '/.config/pdk'
    end
  end

  def host_system_config_file(host)
    # This emulates the PDK::Config.system_config_path method
    system_dir = host_system_configdir(host)
    (host.platform =~ %r{windows}) ? system_dir + '\\\\system_config.json' : system_dir + '/system_config.json'
  end

  def host_user_config_file(host)
    # This emulates the PDK::Config.user_config_path method
    user_dir = host_user_configdir(host)
    (host.platform =~ %r{windows}) ? user_dir + '\\\\user_config.json' : user_dir + '/user_config.json'
  end

  before(:all) do
    hosts.each do |host|
      # Create the sytem configuration directory
      system_dir = host_system_configdir(host)
      host.mkdir_p(system_dir) unless directory_exists_on(host, system_dir)

      # Create the user configuration directory
      # Note that this assumes the user's home directory is already setup with the correct directory permissions
      user_dir = host_user_configdir(host)
      host.mkdir_p(user_dir) unless directory_exists_on(host, user_dir)

      # Setup the system and user test settings
      create_remote_file(host, host_system_config_file(host), "{\n  \"testsetting1\": \"system\"\n}\n")
      create_remote_file(host, host_user_config_file(host), "{\n  \"testsetting1\": \"user\"\n}\n")
    end
  end

  context 'retrieving the configuration' do
    describe command('pdk get config') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to contain('system.testsetting1=system') }
      its(:stdout) { is_expected.to contain('user.testsetting1=user') }
    end
  end

  context 'setting the configuration' do
    describe command('pdk set config system.testsetting2 system2') do
      its(:exit_status) { is_expected.to eq(0) }

      context 'and then retrieving the configuration' do
        # Note this requires the above command to be run first.
        describe command('pdk get config') do
          its(:stdout) { is_expected.to contain('system.testsetting2=system2') }
        end
      end
    end

    describe command('pdk set config user.testsetting2 user2') do
      its(:exit_status) { is_expected.to eq(0) }

      context 'and then retrieving the configuration' do
        # Note this requires the above command to be run first.
        describe command('pdk get config') do
          its(:stdout) { is_expected.to contain('user.testsetting2=user2') }
        end
      end
    end
  end
end

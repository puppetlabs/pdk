require 'spec_helper_package'

describe 'Running PDK as an unprivileged user' do
  module_name = 'unprivileged_user'

  before(:all) do
    hosts.each do |host|
      next if host.platform.include?('windows')

      host.user_present('testuser')

      case host.platform
      when /osx/
        on(host, 'createhomedir -c -u testuser')
      else
        on(host, 'getent passwd testuser') do |result|
          _, _, uid, gid, _, homedir, = result.stdout.strip.split(':')
          on(host, "mkdir #{homedir} && chown #{uid}:#{gid} #{homedir}") unless directory_exists_on(host, homedir)
        end
      end
    end
  end

  let(:run_as) { 'testuser' }

  context 'when creating a new module and new class', unless: windows_node? do
    describe command('whoami') do
      its(:stdout) { is_expected.to contain('testuser') }
    end

    describe command("pdk new module #{module_name} --skip-interview --template-url=https://github.com/puppetlabs/pdk-templates --template-ref=main") do
      its(:exit_status) { is_expected.to eq(0) }
    end

    describe command("pdk new class #{module_name}") do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
    end

    describe command('pdk new defined_type test_define') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
    end
  end

  context 'when unit testing', unless: windows_node? do
    describe command('pdk test unit') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(/[1-9]\d* examples.*0 failures/im) }
    end
  end

  context 'when unit testing in parallel', unless: windows_node? do
    describe command('pdk test unit --parallel') do
      let(:cwd) { module_name }

      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(/[1-9]\d* examples.*0 failures/im) }
    end
  end
end

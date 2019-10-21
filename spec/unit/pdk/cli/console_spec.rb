require 'spec_helper'
require 'pdk/cli'

describe 'pdk console' do
  let(:console_cmd) { PDK::CLI.instance_variable_get(:@console_cmd) }

  before(:each) do
    allow_any_instance_of(PDK::Util::Bundler::BundleHelper).to receive(:gemfile_lock).and_return(File.join(FIXTURES_DIR, 'module_gemfile_lockfile'))
    allow(Bundler).to receive(:default_lockfile).and_return(File.join(FIXTURES_DIR, 'module_gemfile_lockfile'))
    allow(PDK::CLI::Util).to receive(:module_version_check).and_return(true)
  end

  shared_context 'with a mocked rubygems response' do
    before(:each) do
      mock_fetcher = instance_double(Gem::SpecFetcher)
      allow(Gem::SpecFetcher).to receive(:fetcher).and_return(mock_fetcher)

      mock_response = rubygems_versions.map do |version|
        [Gem::NameTuple.new('puppet', Gem::Version.new(version), Gem::Platform.local), nil]
      end

      allow(mock_fetcher).to receive(:detect).with(:released).and_return(mock_response)
    end

    let(:rubygems_versions) do
      %w[
        5.4.0
        5.3.5 5.3.4 5.3.3 5.3.2 5.3.1 5.3.0
        5.2.0
        5.1.0
        5.0.1 5.0.0
        4.10.10 4.10.9 4.10.8 4.10.7 4.10.6 4.10.5 4.10.4 4.10.1 4.10.0
        4.9.4 4.9.3 4.9.2 4.9.1 4.9.0
        4.8.2 4.8.1 4.8.0
        4.7.1 4.7.0
        4.6.2 4.6.1 4.6.0
        4.5.3 4.5.2 4.5.1 4.5.0
        4.4.2 4.4.1 4.4.0
        4.3.2 4.3.1 4.3.0
        4.2.3 4.2.2 4.2.1 4.2.0
      ]
    end

    let(:versions) { rubygems_versions.map { |r| Gem::Version.new(r) } }
  end

  include_context 'with a mocked rubygems response'

  it { expect(console_cmd).not_to be_nil }

  context 'packaged install' do
    include_context 'packaged install'

    before(:each) do
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(true)
      allow(PDK::Util).to receive(:in_module_root?).and_return(true)
      allow(PDK::Util::RubyVersion).to receive(:available_puppet_versions).and_return(versions)
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).and_return(true)
      allow(PDK::CLI::Exec).to receive(:bundle_bin).and_return('/pdk/lib/pdk/util/private/ruby/2.4.4/bin/bundle')
      allow(PDK::Util::PuppetVersion).to receive(:find_in_package_cache).and_return(gem_version: '6.4.0', ruby_version: '2.5.3')
    end

    it 'invokes console with options' do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.4.0')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.4.0')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::Util).to receive(:module_root).and_return('/modules/ntp')
      args = [
        PDK::CLI::Exec.bundle_bin, 'exec', 'puppet',
        'debugger', '--run-once', '--quiet', '--execute=$foo = 123',
        '--basemodulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules',
        '--modulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules'
      ]
      expect(PDK::CLI::Exec::InteractiveCommand).to receive(:new).with(*args).and_return(command)
      expect { console_cmd.run(['--puppet-version=5', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end
  end

  context 'not packaged install' do
    before(:each) do
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(true)
      allow(PDK::Util).to receive(:in_module_root?).and_return(true)
    end

    include_context 'not packaged install'

    it 'invokes console with options' do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.4.0')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.4.0')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::Util).to receive(:module_root).and_return('/modules/ntp')
      args = [
        PDK::CLI::Exec.bundle_bin, 'exec', 'puppet', 'debugger', '--run-once', '--quiet', '--execute=$foo = 123',
        '--basemodulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules',
        '--modulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules'
      ]
      expect(PDK::CLI::Exec::InteractiveCommand).to receive(:new).with(*args).and_return(command)
      expect { console_cmd.run(['--puppet-version=5', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end
  end

  describe 'not in a module' do
    before(:each) do
      allow(PDK::Util).to receive(:in_module_root?).and_return(false)
    end

    it 'invokes console and throws error' do
      expect { console_cmd.run(['console']) }.to raise_error(PDK::CLI::ExitWithError)
    end
  end

  describe 'in a module' do
    before(:each) do
      allow(PDK::CLI::Util).to receive(:ensure_in_module!).and_return(true)
      allow(PDK::Util).to receive(:in_module_root?).and_return(true)
    end

    it 'can pass --puppet-version' do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.4.0')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.4.0')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new).and_return(command)
      expect { console_cmd.run(['--puppet-version=5', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end

    it 'can pass --pe-version' do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with({ :"pe-version" => '2018.1' }, true)
                                                                .and_return(gemset: { puppet: '5.5.10' }, ruby_version: '2.5.3')
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.5.10')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(PDK::Util::RubyVersion).to receive(:versions).and_return('2.5.3' => '2.5.0')
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.5.10')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new).and_return(command)
      expect { console_cmd.run(['--pe-version=2018.1', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end

    it 'can pass --puppet-dev' do
      allow(PDK::CLI::Util).to receive(:puppet_from_opts_or_env).with({ :"puppet-dev" => '' }, true)
                                                                .and_return(gemset: { puppet: 'file:///home/user1/.pdk/cache/src/puppet' }, ruby_version: '2.5.3')
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: 'file:///home/user1/.pdk/cache/src/puppet')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(PDK::Util::RubyVersion).to receive(:versions).and_return('2.5.3' => '2.5.0')
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => 'file:///home/user1/.pdk/cache/src/puppet')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::CLI::Exec::InteractiveCommand).to receive(:new).and_return(command)
      expect { console_cmd.run(['--puppet-dev', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end

    describe 'windows', if: OS.windows? do
      it 'can pass debugger options on windows' do
        allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.4.0')
        command = instance_double(PDK::CLI::Exec::InteractiveCommand)
        allow(command).to receive(:context=).with(:pwd)
        allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.4.0')
        allow(command).to receive(:execute!).and_return(exit_code: 0)
        allow(PDK::Util).to receive(:module_root).and_return('C:/modules/ntp')
        args = [
          PDK::CLI::Exec.bundle_bin, 'exec', 'puppet', 'debugger', '--run-once', '--quiet', '--execute=$foo = 123',
          '--basemodulepath=C:/modules/ntp/spec/fixtures/modules:C:/modules/ntp/modules',
          '--modulepath=C:/modules/ntp/spec/fixtures/modules:C:/modules/ntp/modules'
        ]
        expect(PDK::CLI::Exec::InteractiveCommand).to receive(:new).with(*args).and_return(command)
        expect { console_cmd.run(['--puppet-version=5', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
      end
    end

    it 'can pass debugger options on linux' do
      allow(PDK::Util::Bundler).to receive(:ensure_bundle!).with(puppet: '5.4.0')
      command = instance_double(PDK::CLI::Exec::InteractiveCommand)
      allow(command).to receive(:context=).with(:pwd)
      allow(command).to receive(:update_environment).with('PUPPET_GEM_VERSION' => '5.4.0')
      allow(command).to receive(:execute!).and_return(exit_code: 0)
      allow(PDK::Util).to receive(:module_root).and_return('/modules/ntp')
      args = [
        PDK::CLI::Exec.bundle_bin, 'exec', 'puppet', 'debugger', '--run-once', '--quiet', '--execute=$foo = 123',
        '--basemodulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules',
        '--modulepath=/modules/ntp/spec/fixtures/modules:/modules/ntp/modules'
      ]
      expect(PDK::CLI::Exec::InteractiveCommand).to receive(:new).with(*args).and_return(command)
      expect { console_cmd.run(['--puppet-version=5', '--run-once', '--quiet', '--execute=$foo = 123']) }.to exit_zero
    end
  end
end

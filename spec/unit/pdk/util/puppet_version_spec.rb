require 'spec_helper'
require 'pdk/util/puppet_version'
require 'json'

describe PDK::Util::PuppetVersion do
  shared_context 'with a mocked rubygems response' do
    before(:each) do
      mock_fetcher = instance_double(Gem::SpecFetcher)
      allow(Gem::SpecFetcher).to receive(:fetcher).and_return(mock_fetcher)

      mock_response = rubygems_versions.map do |version|
        [Gem::NameTuple.new('puppet', Gem::Version.new(version), Gem::Platform.local), nil]
      end

      allow(mock_fetcher).to receive(:detect).with(:released).and_return(mock_response)
    end
  end

  # TODO: use existing shared context from spec/support/packaged_install.rb
  shared_context 'is not a package install' do
    before(:each) do
      allow(PDK::Util).to receive(:package_install?).and_return(false)
    end
  end

  # TODO: use existing shared context from spec/support/packaged_install.rb
  shared_context 'is a package install' do
    before(:each) do
      allow(PDK::Util).to receive(:package_install?).and_return(true)
      allow(PDK::Util::RubyVersion).to receive(:versions).and_return('2.1.9' => '2.1.0', '2.4.3' => '2.4.0')

      instance219 = PDK::Util::RubyVersion.instance('2.1.9')
      instance243 = PDK::Util::RubyVersion.instance('2.4.3')

      versions219 = cache_versions.select { |r| r.start_with?('4') }.map { |r| Gem::Version.new(r) }
      versions243 = cache_versions.reject { |r| r.start_with?('4') }.map { |r| Gem::Version.new(r) }
      allow(instance219).to receive(:available_puppet_versions).and_return(versions219)
      allow(instance243).to receive(:available_puppet_versions).and_return(versions243)
    end

    after(:each) do
      PDK::Util::RubyVersion.instance_variable_set('@instance', nil)
      PDK::Util::RubyVersion.instance_variable_set('@active_ruby_version', nil)
    end
  end

  let(:forge_version_map) do
    JSON.parse(open(File.join(RSpec.configuration.root, 'fixtures', 'pe_versions.json')).read)
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

  let(:cache_versions) do
    %w[5.5.1 5.4.0 5.3.6 5.2.0 5.1.0 5.0.1 4.10.11 4.9.4 4.8.2 4.9.4 4.7.1]
  end

  describe '.latest_available' do
    subject { described_class.latest_available }

    let(:expected_version) do
      versions.sort { |a, b| b <=> a }.first
    end

    context 'when running from a package install' do
      include_context 'is a package install'
      let(:versions) { PDK::Util::RubyVersion.available_puppet_versions }

      it { is_expected.to include(gem_version: expected_version) }
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'
      include_context 'with a mocked rubygems response'

      let(:versions) { rubygems_versions.map { |r| Gem::Version.new(r) } }

      it { is_expected.to include(gem_version: expected_version) }
    end
  end

  describe '.fetch_puppet_dev' do
    context 'if puppet source is not cloned yet' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:remote_repo?).with(anything).and_return(false)
      end

      context 'and fails to connect to github' do
        let(:clone_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 1,
          }
        end

        before(:each) do
          allow(PDK::Util).to receive(:cachedir).and_return(File.join('path', 'to'))
          allow(PDK::Util::Git).to receive(:git).with('clone', anything, anything).and_return(clone_results)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(a_string_matching(%r{foo}))
          expect(logger).to receive(:error).with(a_string_matching(%r{bar}))
          expect {
            described_class.fetch_puppet_dev
          }.to raise_error(PDK::CLI::FatalError, a_string_matching(%r{Unable to clone git repository}i))
        end
      end

      context 'and successfully connects to github' do
        let(:clone_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 0,
          }
        end

        before(:each) do
          allow(PDK::Util).to receive(:cachedir).and_return(File.join('path', 'to'))
          allow(PDK::Util::Git).to receive(:git).with('clone', anything, anything).and_return(clone_results)
        end

        it 'exits cleanly' do
          expect(described_class.fetch_puppet_dev).to eq(nil)
        end
      end
    end

    context 'if puppet source is already cloned' do
      before(:each) do
        allow(PDK::Util::Git).to receive(:remote_repo?).with(anything).and_return(true)
      end

      context 'and fails to connect to github' do
        let(:fetch_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 1,
          }
        end

        before(:each) do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('fetch', anything, anything).and_return(fetch_results)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(a_string_matching(%r{foo}))
          expect(logger).to receive(:error).with(a_string_matching(%r{bar}))
          expect {
            described_class.fetch_puppet_dev
          }.to raise_error(PDK::CLI::FatalError, a_string_matching(%r{Unable to fetch updates for git repository}i))
        end
      end

      context 'and successfully connects to github' do
        let(:clone_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 0,
          }
        end

        before(:each) do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('fetch', anything, anything).and_return(clone_results)
        end

        it 'exits cleanly' do
          expect(described_class.fetch_puppet_dev).to eq(nil)
        end
      end
    end
  end

  describe '.find_gem_for' do
    context 'when running from a package install' do
      include_context 'is a package install'

      context 'and passed an invalid version number' do
        it 'raises an ArgumentError' do
          expect {
            described_class.find_gem_for('irving')
          }.to raise_error(ArgumentError, %r{not a valid version number}i)
        end
      end

      context 'and passed only a major version' do
        it 'returns the latest version matching the major version' do
          expected_result = {
            gem_version:  Gem::Version.new('5.5.1'),
            ruby_version: '2.4.3',
          }
          expect(described_class.find_gem_for('5')).to eq(expected_result)
        end
      end

      context 'and passed only a major and minor version' do
        it 'returns the latest patch version for the major and minor version' do
          expected_result = {
            gem_version:  Gem::Version.new('5.3.6'),
            ruby_version: '2.4.3',
          }
          expect(described_class.find_gem_for('5.3')).to eq(expected_result)
        end
      end

      it 'returns the specified version if it exists in the cache' do
        expected_result = {
          gem_version:  Gem::Version.new('5.3.6'),
          ruby_version: '2.4.3',
        }
        expect(described_class.find_gem_for('5.3.6')).to eq(expected_result)
      end

      context 'and the specified version does not exist in the cache' do
        it 'notifies the user that it is using the latest Z release instead' do
          expect(logger).to receive(:warn).with(a_string_matching(%r{activating 5\.3\.6 instead}i))
          described_class.find_gem_for('5.3.1')
        end

        it 'returns the latest Z release' do
          expected_result = {
            gem_version:  Gem::Version.new('5.3.6'),
            ruby_version: '2.4.3',
          }
          expect(described_class.find_gem_for('5.3.1')).to eq(expected_result)
        end

        it 'raises an ArgumentError if no version can be found' do
          expect {
            described_class.find_gem_for('1.0.0')
          }.to raise_error(ArgumentError, %r{unable to find a puppet gem matching}i)
        end
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'
      include_context 'with a mocked rubygems response'

      def result(version)
        {
          gem_version:  Gem::Version.new(version),
          ruby_version: PDK::Util::RubyVersion.default_ruby_version,
        }
      end

      context 'and passed an invalid version number' do
        it 'raises an ArgumentError' do
          expect {
            described_class.find_gem_for('irving')
          }.to raise_error(ArgumentError, %r{not a valid version number}i)
        end
      end

      context 'and passed only a major version' do
        it 'returns the latest version matching the major version' do
          expect(described_class.find_gem_for('5')).to eq(result('5.4.0'))
        end
      end

      context 'and passed only a major and minor version' do
        it 'returns the latest patch version for the major and minor version' do
          expect(described_class.find_gem_for('5.3')).to eq(result('5.3.5'))
        end
      end

      it 'returns the specified version if it exists on Rubygems' do
        expect(described_class.find_gem_for('4.9.0')).to eq(result('4.9.0'))
      end

      context 'and the specified version does not exist on Rubygems' do
        it 'notifies the user that it is using the latest Z release instead' do
          expect(logger).to receive(:warn).with(a_string_matching(%r{activating 4\.10\.10 instead}i))
          described_class.find_gem_for('4.10.999')
        end

        it 'returns the latest Z release' do
          expect(described_class.find_gem_for('4.10.999')).to eq(result('4.10.10'))
        end

        it 'raises an ArgumentError if no version can be found' do
          expect {
            described_class.find_gem_for('1.0.0')
          }.to raise_error(ArgumentError, %r{unable to find a puppet gem matching}i)
        end
      end
    end
  end

  describe '.from_pe_version' do
    before(:each) do
      allow(described_class.instance).to receive(:fetch_pe_version_map).and_return(forge_version_map)
    end

    after(:each) do
      # Clear memoization of the version map between specs
      described_class.instance.instance_variable_set(:@pe_version_map, nil)
    end

    context 'when running from a package install' do
      include_context 'is a package install'

      def result(pe_version)
        version_info = if pe_version.count('.') == 2
                         forge_version_map.map { |r| r['versions'] }.flatten.find { |r| r['version'] == pe_version }
                       else
                         forge_version_map.find { |r| r['release'] == "#{pe_version}.x" }['versions'].first
                       end

        if cache_versions.include?(version_info['puppet'])
          gem_version = version_info['puppet']
        else
          requirement = Gem::Requirement.create("~> #{version_info['puppet'].gsub(%r{\.\d+\Z}, '.0')}")
          gem_version = cache_versions.find { |r| requirement.satisfied_by? Gem::Version.new(r) }
        end

        {
          gem_version:  Gem::Version.new(gem_version),
          ruby_version: a_string_starting_with(version_info['ruby'].gsub(%r{\.\d+\Z}, '')),
        }
      end

      it 'returns the latest Puppet Z release for PE 2017.3.x' do
        expect(described_class.from_pe_version('2017.3')).to include(result('2017.3'))
        expect(described_class.from_pe_version('2017.3.1')).to include(result('2017.3.1'))
      end

      it 'returns the latest Puppet Z release for PE 2017.2.x' do
        expect(described_class.from_pe_version('2017.2')).to include(result('2017.2'))
        expect(described_class.from_pe_version('2017.2.1')).to include(result('2017.2.1'))
      end

      it 'returns the latest Puppet Z release for PE 2017.1.x' do
        expect(described_class.from_pe_version('2017.1')).to include(result('2017.1'))
        expect(described_class.from_pe_version('2017.1.1')).to include(result('2017.1.1'))
      end

      it 'returns the latest Puppet Z release for PE 2016.5.x' do
        expect(described_class.from_pe_version('2016.5')).to include(result('2016.5'))
        expect(described_class.from_pe_version('2016.5.1')).to include(result('2016.5.1'))
      end

      it 'returns the latest Puppet Z release for PE 2016.4.x' do
        expect(described_class.from_pe_version('2016.4')).to include(result('2016.4'))
        expect(described_class.from_pe_version('2016.4.10')).to include(result('2016.4.10'))
      end

      it 'raises an ArgumentError if given an unknown PE version' do
        expect {
          described_class.from_pe_version('9999.1.1')
        }.to raise_error(ArgumentError, %r{unable to map puppet enterprise version}i)
      end

      it 'raises an ArgumentError if given an invalid version string' do
        expect {
          described_class.from_pe_version('irving')
        }.to raise_error(ArgumentError, %r{not a valid version number}i)
      end

      context 'when the vendored mapping file is invalid JSON' do
        let(:vendored_file) { instance_double(PDK::Util::VendoredFile, read: 'invalid json') }

        before(:each) do
          allow(described_class.instance).to receive(:fetch_pe_version_map).and_call_original
          allow(PDK::Util::VendoredFile).to receive(:new).with('pe_versions.json', anything).and_return(vendored_file)
        end

        it 'raises a FatalError' do
          expect {
            described_class.from_pe_version('2017.3')
          }.to raise_error(PDK::CLI::FatalError, %r{failed to parse puppet enterprise version map file}i)
        end
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'
      include_context 'with a mocked rubygems response'

      def result(pe_version)
        version_info = if pe_version.count('.') == 2
                         forge_version_map.map { |r| r['versions'] }.flatten.find { |r| r['version'] == pe_version }
                       else
                         forge_version_map.find { |r| r['release'] == "#{pe_version}.x" }['versions'].first
                       end

        {
          gem_version:  Gem::Version.new(version_info['puppet']),
          ruby_version: PDK::Util::RubyVersion.default_ruby_version,
        }
      end

      it 'returns the latest Puppet Z release for PE 2017.3.x' do
        expect(described_class.from_pe_version('2017.3')).to eq(result('2017.3'))
        expect(described_class.from_pe_version('2017.3.1')).to eq(result('2017.3.1'))
      end

      it 'returns the latest Puppet Z release for PE 2017.2.x' do
        expect(described_class.from_pe_version('2017.2')).to eq(result('2017.2'))
        expect(described_class.from_pe_version('2017.2.1')).to eq(result('2017.2.1'))
      end

      it 'returns the latest Puppet Z release for PE 2017.1.x' do
        expect(described_class.from_pe_version('2017.1')).to eq(result('2017.1'))
        expect(described_class.from_pe_version('2017.1.1')).to eq(result('2017.1.1'))
      end

      it 'returns the latest Puppet Z release for PE 2016.5.x' do
        expect(described_class.from_pe_version('2016.5')).to eq(result('2016.5'))
        expect(described_class.from_pe_version('2016.5.1')).to eq(result('2016.5.1'))
      end

      it 'returns the latest Puppet Z release for PE 2016.4.x' do
        expect(described_class.from_pe_version('2016.4')).to eq(result('2016.4'))
        expect(described_class.from_pe_version('2016.4.2')).to eq(result('2016.4.2'))
      end

      it 'raises an ArgumentError if given an unknown PE version' do
        expect {
          described_class.from_pe_version('9999.1.1')
        }.to raise_error(ArgumentError, %r{unable to map puppet enterprise version}i)
      end

      it 'raises an ArgumentError if given an invalid version string' do
        expect {
          described_class.from_pe_version('irving')
        }.to raise_error(ArgumentError, %r{not a valid version number}i)
      end

      context 'when there is an error downloading the mapping file' do
        before(:each) do
          allow(described_class.instance).to receive(:fetch_pe_version_map).and_call_original
          allow(PDK::Util::VendoredFile).to receive(:new).with('pe_versions.json', anything).and_raise(PDK::Util::VendoredFile::DownloadError, 'download failed for reasons')
        end

        it 'raises a FatalError' do
          expect {
            described_class.from_pe_version('2017.3')
          }.to raise_error(PDK::CLI::FatalError, %r{download failed for reasons}i)
        end
      end

      context 'when the vendored mapping file is invalid JSON' do
        let(:vendored_file) { instance_double(PDK::Util::VendoredFile, read: 'invalid json') }

        before(:each) do
          allow(described_class.instance).to receive(:fetch_pe_version_map).and_call_original
          allow(PDK::Util::VendoredFile).to receive(:new).with('pe_versions.json', anything).and_return(vendored_file)
        end

        it 'raises a FatalError' do
          expect {
            described_class.from_pe_version('2017.3')
          }.to raise_error(PDK::CLI::FatalError, %r{failed to parse puppet enterprise version map file}i)
        end
      end
    end
  end

  describe '.from_module_metadata' do
    let(:metadata) { PDK::Module::Metadata.new }

    context 'with default metadata' do
      it 'searches for a Puppet gem >= 4.7.0 < 6.0.0' do
        requirement = Gem::Requirement.create(['>= 4.7.0', '< 6.0.0'])
        expect(described_class.instance).to receive(:find_gem).with(requirement)

        described_class.from_module_metadata(metadata)
      end
    end

    context 'with a pinned version requirement' do
      before(:each) do
        metadata.data['requirements'] = [{ 'name' => 'puppet', 'version_requirement' => '4.10.10' }]
      end

      it 'searches for a Puppet gem matching the exact version' do
        expect(described_class.instance).to receive(:find_gem).with(Gem::Requirement.create('4.10.10'))

        described_class.from_module_metadata(metadata)
      end
    end

    context 'with an invalid version requirement' do
      before(:each) do
        metadata.data['requirements'] = [{ 'name' => 'puppet', 'version_requirement' => '' }]
      end

      it 'raises an ArgumentError' do
        expect {
          described_class.from_module_metadata(metadata)
        }.to raise_error(ArgumentError)
      end
    end

    context 'when module has no metadata.json' do
      before(:each) do
        allow(PDK::Util).to receive(:find_upwards).with('metadata.json').and_return(nil)
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(%r{no metadata\.json present}i)

        described_class.from_module_metadata
      end

      it 'returns nil' do
        expect(described_class.from_module_metadata).to be_nil
      end
    end
  end
end

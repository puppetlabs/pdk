require 'spec_helper'
require 'pdk/util/puppet_version'
require 'json'

describe PDK::Util::PuppetVersion do
  let(:cache_versions) do
    ['6.29.0', '7.23.0']
  end

  let(:rubygems_versions) do
    ['7.23.0', '6.29.0']
  end

  let(:forge_version_map) do
    JSON.parse(PDK::Util::Filesystem.read_file(File.join(RSpec.configuration.root, 'fixtures', 'pe_versions.json')))
  end

  shared_context 'with a mocked rubygems response' do
    before do
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
    before do
      allow(PDK::Util).to receive(:package_install?).and_return(false)
    end
  end

  # TODO: use existing shared context from spec/support/packaged_install.rb
  shared_context 'is a package install' do
    before do
      allow(PDK::Util).to receive(:package_install?).and_return(true)
      allow(PDK::Util::RubyVersion).to receive(:versions).and_return('2.5.9' => '2.5.0', '2.7.7' => '2.7.0')

      instance259 = PDK::Util::RubyVersion.instance('2.5.9')
      instance277 = PDK::Util::RubyVersion.instance('2.7.7')

      versions259 = cache_versions.select { |r| r.start_with?('6') }.map { |r| Gem::Version.new(r) }
      versions277 = cache_versions.reject { |r| r.start_with?('6') }.map { |r| Gem::Version.new(r) }
      allow(instance259).to receive(:available_puppet_versions).and_return(versions259)
      allow(instance277).to receive(:available_puppet_versions).and_return(versions277)
    end

    after do
      PDK::Util::RubyVersion.instance_variable_set(:@instance, nil)
      PDK::Util::RubyVersion.instance_variable_set(:@active_ruby_version, nil)
    end
  end

  describe '.latest_available' do
    subject { described_class.latest_available }

    let(:expected_version) do
      versions.max
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
    context 'if puppet source has already been fetched' do
      before do
        allow(described_class.instance).to receive(:puppet_dev_fetched?).and_return(true)
      end

      context 'when run with :run => :once' do
        it 'does not perform any git operations' do
          expect(PDK::Util::Git).not_to receive(:git)

          described_class.fetch_puppet_dev(run: :once)
        end
      end

      context 'when not run with :run => :once' do
        it 'performs the git operations' do
          allow(PDK::Util::Git).to receive(:remote_repo?).with(anything).and_return(true)
          allow(PDK::Util).to receive(:cachedir).and_return(File.join('path', 'to'))

          expect(PDK::Util::Git).to receive(:git).with(any_args).and_return(exit_code: 0).twice

          described_class.fetch_puppet_dev
        end
      end
    end

    context 'if puppet source is not cloned yet' do
      before do
        allow(PDK::Util::Git).to receive(:remote_repo?).with(anything).and_return(false)
      end

      context 'and fails to connect to github' do
        let(:clone_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 1
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return(File.join('path', 'to'))
          allow(PDK::Util::Git).to receive(:git).with('clone', anything, anything).and_return(clone_results)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(a_string_matching(/foo/))
          expect(logger).to receive(:error).with(a_string_matching(/bar/))
          expect do
            described_class.fetch_puppet_dev
          end.to raise_error(PDK::CLI::FatalError, a_string_matching(/Unable to clone git repository/i))
        end
      end

      context 'and successfully connects to github' do
        let(:clone_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 0
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return(File.join('path', 'to'))
          allow(PDK::Util::Git).to receive(:git).with('clone', anything, anything).and_return(clone_results)
        end

        it 'exits cleanly' do
          expect(described_class.fetch_puppet_dev).to be_nil
        end
      end
    end

    context 'if puppet source is already cloned' do
      before do
        allow(PDK::Util::Git).to receive(:remote_repo?).with(anything).and_return(true)
      end

      context 'and fails to connect to github' do
        let(:fetch_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 1
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'fetch', 'origin').and_return(fetch_results)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(a_string_matching(/foo/))
          expect(logger).to receive(:error).with(a_string_matching(/bar/))
          expect do
            described_class.fetch_puppet_dev
          end.to raise_error(PDK::CLI::FatalError, a_string_matching(/Unable to fetch from git remote at/i))
        end
      end

      context 'and successfully connects to github' do
        let(:fetch_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 0
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'fetch', 'origin').and_return(fetch_results)
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'reset', '--hard', 'origin/main').and_return(exit_code: 0)
        end

        it 'exits cleanly' do
          expect(described_class.fetch_puppet_dev).to be_nil
        end
      end

      context 'and fails update repo' do
        let(:reset_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 1
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'fetch', 'origin').and_return(exit_code: 0)
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'reset', '--hard', 'origin/main').and_return(reset_results)
        end

        it 'raises an error' do
          expect(logger).to receive(:error).with(a_string_matching(/foo/))
          expect(logger).to receive(:error).with(a_string_matching(/bar/))
          expect do
            described_class.fetch_puppet_dev
          end.to raise_error(PDK::CLI::FatalError, a_string_matching(/Unable to update git repository/i))
        end
      end

      context 'and successfully updates repo' do
        let(:reset_results) do
          {
            stdout: 'foo',
            stderr: 'bar',
            exit_code: 0
          }
        end

        before do
          allow(PDK::Util).to receive(:cachedir).and_return('/path/to/')
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'fetch', 'origin').and_return(exit_code: 0)
          allow(PDK::Util::Git).to receive(:git).with('-C', anything, 'reset', '--hard', 'origin/main').and_return(reset_results)
        end

        it 'exits cleanly' do
          expect(described_class.fetch_puppet_dev).to be_nil
        end
      end
    end
  end

  describe '.find_gem_for' do
    context 'when running from a package install' do
      include_context 'is a package install'

      context 'and passed an invalid version number' do
        it 'raises an ArgumentError' do
          expect do
            described_class.find_gem_for('irving')
          end.to raise_error(ArgumentError, /not a valid version number/i)
        end
      end

      context 'and passed only a major version' do
        it 'returns the latest version matching the major version' do
          expected_result = {
            gem_version: Gem::Version.new('6.29.0'),
            ruby_version: '2.5.9'
          }
          expect(described_class.find_gem_for('6')).to eq(expected_result)
        end
      end

      context 'and passed only a major and minor version' do
        it 'returns the latest patch version for the major and minor version' do
          expected_result = {
            gem_version: Gem::Version.new('6.29.0'),
            ruby_version: '2.5.9'
          }
          expect(described_class.find_gem_for('6.29')).to eq(expected_result)
        end
      end

      it 'returns the specified version if it exists in the cache' do
        expected_result = {
          gem_version: Gem::Version.new('6.29.0'),
          ruby_version: '2.5.9'
        }
        expect(described_class.find_gem_for('6.29.0')).to eq(expected_result)
      end

      context 'and the specified version does not exist in the cache' do
        it 'raises an ArgumentError if no version can be found' do
          expect do
            described_class.find_gem_for('1.0.0')
          end.to raise_error(ArgumentError, /unable to find a puppet gem matching/i)
        end
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'
      include_context 'with a mocked rubygems response'

      def result(version)
        {
          gem_version: Gem::Version.new(version),
          ruby_version: PDK::Util::RubyVersion.default_ruby_version
        }
      end

      context 'and passed an invalid version number' do
        it 'raises an ArgumentError' do
          expect do
            described_class.find_gem_for('irving')
          end.to raise_error(ArgumentError, /not a valid version number/i)
        end
      end

      context 'and passed only a major version' do
        it 'returns the latest version matching the major version' do
          expect(described_class.find_gem_for('6')).to eq(result('6.29.0'))
        end
      end

      context 'and passed only a major and minor version' do
        it 'returns the latest patch version for the major and minor version' do
          expect(described_class.find_gem_for('6.29')).to eq(result('6.29.0'))
        end
      end

      it 'returns the specified version if it exists on Rubygems' do
        expect(described_class.find_gem_for('6.29.0')).to eq(result('6.29.0'))
      end
    end
  end

  describe '.from_pe_version' do
    before do
      allow(described_class.instance).to receive(:fetch_pe_version_map).and_return(forge_version_map)
    end

    after do
      # Clear memoization of the version map between specs
      described_class.instance.instance_variable_set(:@pe_version_map, nil)
    end

    context 'when running from a package install' do
      include_context 'is a package install'

      def result(pe_version)
        safe_versions = {
          2023 => {
            'puppet' => '7.23.0',
            'ruby' => '2.7.7'
          },
          2021 => {
            'puppet' => '7.23.0',
            'ruby' => '2.7.7'
          },
          2019 => {
            'puppet' => '6.29.0',
            'ruby' => '2.5.9'
          }
        }

        parsed_version = Gem::Version.new(pe_version)

        version_info = safe_versions[parsed_version.segments[0]]

        if cache_versions.include?(version_info['puppet'])
          gem_version = version_info['puppet']
        else
          requirement = Gem::Requirement.create("~> #{version_info['puppet'].gsub(/\.\d+\Z/, '.0')}")
          gem_version = cache_versions.find { |r| requirement.satisfied_by? Gem::Version.new(r) }
        end

        {
          gem_version: Gem::Version.new(gem_version),
          ruby_version: version_info['ruby']
        }
      end

      it 'returns the latest Puppet Z release for PE 2023.0.x' do
        expect(described_class.from_pe_version('2023.0')).to include(result('2023.0'))
        expect(described_class.from_pe_version('2023.0.0')).to include(result('2023.0'))
      end

      it 'returns the latest Puppet Z release for PE 2021.7.x' do
        expect(described_class.from_pe_version('2021.7')).to include(result('2021.7'))
        expect(described_class.from_pe_version('2021.7.2')).to include(result('2021.7.2'))
      end

      it 'returns the latest Puppet Z release for PE 2019.8.x' do
        expect(described_class.from_pe_version('2019.8')).to include(result('2019.8'))
        expect(described_class.from_pe_version('2019.8.12')).to include(result('2019.8.12'))
      end

      it 'raises an ArgumentError if given an unknown PE version' do
        expect do
          described_class.from_pe_version('9999.1.1')
        end.to raise_error(ArgumentError, /unable to map puppet enterprise version/i)
      end

      it 'raises an ArgumentError if given an invalid version string' do
        expect do
          described_class.from_pe_version('irving')
        end.to raise_error(ArgumentError, /not a valid version number/i)
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'
      include_context 'with a mocked rubygems response'

      def result(pe_version)
        safe_versions = {
          2023 => {
            'puppet' => '7.23.0',
            'ruby' => '2.7.7'
          },
          2021 => {
            'puppet' => '7.23.0',
            'ruby' => '2.7.7'
          },
          2019 => {
            'puppet' => '6.29.0',
            'ruby' => '2.5.9'
          }
        }

        parsed_version = Gem::Version.new(pe_version)
        version_info = safe_versions[parsed_version.segments[0]]

        {
          gem_version: Gem::Version.new(version_info['puppet']),
          ruby_version: PDK::Util::RubyVersion.default_ruby_version
        }
      end

      it 'returns the latest Puppet Z release for PE 2023.0.x' do
        expect(described_class.from_pe_version('2023.0')).to include(result('2023.0'))
        expect(described_class.from_pe_version('2023.0.0')).to include(result('2023.0'))
      end

      it 'returns the latest Puppet Z release for PE 2021.7.x' do
        expect(described_class.from_pe_version('2021.7')).to include(result('2021.7'))
        expect(described_class.from_pe_version('2021.7.2')).to include(result('2021.7.2'))
      end

      it 'returns the latest Puppet Z release for PE 2019.8.x' do
        expect(described_class.from_pe_version('2019.8')).to include(result('2019.8'))
        expect(described_class.from_pe_version('2019.8.12')).to include(result('2019.8.12'))
      end

      it 'raises an ArgumentError if given an unknown PE version' do
        expect do
          described_class.from_pe_version('9999.1.1')
        end.to raise_error(ArgumentError, /unable to map puppet enterprise version/i)
      end

      it 'raises an ArgumentError if given an invalid version string' do
        expect do
          described_class.from_pe_version('irving')
        end.to raise_error(ArgumentError, /not a valid version number/i)
      end
    end
  end

  describe '.from_module_metadata' do
    let(:metadata) { PDK::Module::Metadata.new }

    context 'with default metadata' do
      it 'searches for a Puppet gem >= 6.21.0 < 8.0.0' do
        requirement = Gem::Requirement.create(['>= 6.21.0', '< 8.0.0'])
        expect(described_class.instance).to receive(:find_gem).with(requirement)

        described_class.from_module_metadata(metadata)
      end
    end

    context 'with a pinned version requirement' do
      before do
        metadata.data['requirements'] = [{ 'name' => 'puppet', 'version_requirement' => '4.10.10' }]
      end

      it 'searches for a Puppet gem matching the exact version' do
        expect(described_class.instance).to receive(:find_gem).with(Gem::Requirement.create('4.10.10'))

        described_class.from_module_metadata(metadata)
      end
    end

    context 'with an invalid version requirement' do
      before do
        metadata.data['requirements'] = [{ 'name' => 'puppet', 'version_requirement' => '' }]
      end

      it 'raises an ArgumentError' do
        expect do
          described_class.from_module_metadata(metadata)
        end.to raise_error(ArgumentError)
      end
    end

    context 'when module has no metadata.json' do
      before do
        allow(PDK::Util).to receive(:find_upwards).with('metadata.json').and_return(nil)
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(/no metadata\.json present/i)

        described_class.from_module_metadata
      end

      it 'returns nil' do
        expect(described_class.from_module_metadata).to be_nil
      end
    end
  end
end

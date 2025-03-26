require 'spec_helper'
require 'pdk/util/ruby_version'

describe PDK::Util::RubyVersion do
  let(:instance) { described_class.new }

  shared_context 'is a package install' do
    let(:pdk_package_basedir) do
      File.join('/', 'path', 'to', 'pdk')
    end

    let(:package_cachedir) do
      File.join(pdk_package_basedir, 'share', 'cache')
    end

    let(:packaged_rubies) do
      {
        '2.4.4' => '2.4.0',
        '2.1.9' => '2.1.0'
      }
    end

    before do
      allow(PDK::Util).to receive_messages(package_install?: true, pdk_package_basedir:, package_cachedir:)
      allow(described_class).to receive(:scan_for_packaged_rubies).and_return(packaged_rubies)
    end
  end

  shared_context 'is not a package install' do
    before do
      allow(PDK::Util).to receive(:package_install?).and_return(false)
      bundler_basedir = File.join('/', 'usr', 'lib', 'ruby', 'gems', '2.1.0', 'gems', 'bundler-1.16.1', 'lib')
      allow(instance).to receive(:bundler_basedir).and_return(bundler_basedir)
    end
  end

  describe '#bin_path' do
    subject { instance.bin_path }

    context 'when running from a package install' do
      include_context 'is a package install'

      [PDK_VERSION[:lts][:ruby], PDK_VERSION[:latest][:ruby]].each do |ruby_version|
        context "when the active ruby version is #{ruby_version}" do
          let(:instance) { described_class.new(ruby_version) }

          it "returns the path to the bin dir for the vendored Ruby #{ruby_version}" do
            expect(subject).to eq(File.join(pdk_package_basedir, 'private', 'ruby', ruby_version, 'bin'))
          end
        end
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'

      it 'returns the path to the bin dir for the running ruby' do
        expect(subject).to eq(RbConfig::CONFIG['bindir'])
      end
    end
  end

  describe '#gem_path' do
    subject { instance.gem_path }

    context 'when running from a package install' do
      include_context 'is a package install'

      before do
        # require 'pry'; binding.pry;
        allow(described_class).to receive_messages(versions: packaged_rubies, default_ruby_version: '2.4.4')
      end

      it 'includes the path to the packaged ruby cachedir' do
        expect(subject).to include(File.join(package_cachedir, 'ruby', described_class.versions[described_class.active_ruby_version]))
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'

      it 'returns the gem path relative to bundler' do
        path = File.absolute_path(File.join('/', 'usr', 'lib', 'ruby', 'gems', '2.1.0'))
        expect(subject).to eq(path)
      end
    end
  end

  describe '#gem_home' do
    subject { instance.gem_home }

    let(:cachedir) { File.join('/', 'path', 'to', 'user', 'cache') }

    before do
      allow(PDK::Util).to receive(:cachedir).and_return(cachedir)
    end

    it 'returns a Ruby version specific path under the user cachedir' do
      expect(subject).to eq(File.join(cachedir, 'ruby', described_class.versions[described_class.active_ruby_version]))
    end
  end

  describe '.versions' do
    subject { described_class.versions }

    before do
      described_class.instance_variable_set(:@versions, nil)
    end

    context 'when running from a package install' do
      include_context 'is a package install'

      before do
        basedir = File.join('/', 'basedir')
        ruby_dirs = ['2.1.9', '2.4.4'].map { |r| File.join(basedir, 'private', 'ruby', r) }
        allow(PDK::Util).to receive(:pdk_package_basedir).and_return(basedir)
        allow(PDK::Util::Filesystem).to receive(:glob).with(File.join(basedir, 'private', 'ruby', '*')).and_return(ruby_dirs)
      end

      it 'returns the Ruby versions included in the package' do
        expect(subject).to eq('2.1.9' => '2.1.0', '2.4.4' => '2.4.0')
      end
    end

    context 'when not running from a package install' do
      include_context 'is not a package install'

      it 'returns the running Ruby version' do
        running_ruby = {
          RbConfig::CONFIG['RUBY_PROGRAM_VERSION'] => RbConfig::CONFIG['ruby_version']
        }

        expect(subject).to eq(running_ruby)
      end
    end
  end

  describe '#available_puppet_versions' do
    subject { instance.available_puppet_versions }

    let(:gem_path) { File.join('/', 'path', 'to', 'ruby', 'gem_path') }
    let(:gem_path_pattern) { File.join(gem_path, 'specifications', '**', 'puppet*.gemspec') }
    let(:gem_home) { File.join('/', 'path', 'to', 'ruby', 'gem_home') }
    let(:gem_home_pattern) { File.join(gem_home, 'specifications', '**', 'puppet*.gemspec') }
    let(:gem_path_results) do
      results = {}
      [{ name: 'puppet', version: PDK_VERSION[:lts][:full] }, { name: 'puppet-lint', version: '1.0.0' }].each do |spec_info|
        spec_path = File.join(gem_home, 'specifications', "#{spec_info[:name]}-#{spec_info[:version]}.gemspec")
        spec_definition = Gem::Specification.new do |spec|
          spec.name = spec_info[:name]
          spec.version = spec_info[:version]
        end
        results[spec_path] = spec_definition
      end
      results
    end
    let(:gem_home_results) do
      results = {}
      [{ name: 'puppet', version: PDK_VERSION[:latest][:full] }].each do |spec_info|
        spec_path = File.join(gem_home, 'specifications', "#{spec_info[:name]}-#{spec_info[:version]}.gemspec")
        spec_definition = Gem::Specification.new do |spec|
          spec.name = spec_info[:name]
          spec.version = spec_info[:version]
        end
        results[spec_path] = spec_definition
      end
      results
    end

    before do
      allow(instance).to receive_messages(gem_path:, gem_home:)
      allow(PDK::Util::Filesystem).to receive(:glob).with(gem_path_pattern).and_return(gem_path_results.keys)
      allow(PDK::Util::Filesystem).to receive(:glob).with(gem_home_pattern).and_return(gem_home_results.keys)

      gem_path_results.merge(gem_home_results).each do |spec_path, spec_definition|
        allow(Gem::Specification).to receive(:load).with(spec_path).and_return(spec_definition)
      end
    end

    it 'does not return versions for similarly named gems' do
      expect(subject).not_to include(Gem::Version.new('1.0.0'))
    end

    it 'returns an ordered list of Puppet gem versions' do
      expect(subject).to eq([Gem::Version.new(PDK_VERSION[:latest][:full]), Gem::Version.new(PDK_VERSION[:lts][:full])])
    end
  end
end

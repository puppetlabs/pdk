require 'spec_helper'

describe PDK::Util do
  shared_context :with_version_file, version_file: true do
    let(:version_file) { File.join('path', 'to', 'the', 'version', 'file') }

    before(:each) do
      allow(PDK::Util::Version).to receive(:version_file).and_return(version_file)
    end
  end

  shared_context :without_version_file, version_file: false do
    before(:each) do
      allow(PDK::Util::Version).to receive(:version_file).and_return(nil)
    end
  end

  describe '.find_upwards' do
    subject { described_class.find_upwards(target, start_dir) }

    let(:target) { 'metadata.json' }
    let(:start_dir) { nil }
    let(:actual_start_dir) { '/path/to/something/deep/in/a/module' }

    before(:each) do
      allow(File).to receive(:directory?).with('/path/to/something/deep/in/a/module').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to/something/deep/in/a/module').and_return('/path/to/something/deep/in/a')
      allow(File).to receive(:directory?).with('/path/to/something/deep/in/a').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to/something/deep/in/a').and_return('/path/to/something/deep/in')
      allow(File).to receive(:directory?).with('/path/to/something/deep/in').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to/something/deep/in').and_return('/path/to/something/deep')
      allow(File).to receive(:directory?).with('/path/to/something/deep').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to/something/deep').and_return('/path/to/something')
      allow(File).to receive(:directory?).with('/path/to/something').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to/something').and_return('/path/to')
      allow(File).to receive(:directory?).with('/path/to').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path/to').and_return('/path')
      allow(File).to receive(:directory?).with('/path').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/path').and_return('/')
      allow(File).to receive(:directory?).with('/').and_return(true)
      allow(File).to receive(:expand_path).with('..', '/').and_return('/')
      allow(File).to receive(:expand_path).with(actual_start_dir).and_return(actual_start_dir)
      allow(File).to receive(:file?).with(a_string_matching(%r{metadata\.json\Z})).and_return(false)
    end

    context 'when start_dir is nil' do
      before(:each) do
        allow(Dir).to receive(:pwd).and_return(actual_start_dir)
      end

      context 'and the target file exists' do
        before(:each) do
          allow(File).to receive(:file?).with('/path/to/something/metadata.json').and_return(true)
        end

        it { is_expected.to eq('/path/to/something/metadata.json') }
      end

      context 'and the target file does not exist' do
        it { is_expected.to be_nil }
      end
    end

    context 'when given a start_dir' do
      let(:start_dir) { actual_start_dir }

      context 'and the target file exists' do
        before(:each) do
          allow(File).to receive(:file?).with('/path/to/something/metadata.json').and_return(true)
        end

        it { is_expected.to eq('/path/to/something/metadata.json') }
      end

      context 'and the target file does not exist' do
        it { is_expected.to be_nil }
      end
    end
  end

  describe '.make_tmpdir_name' do
    subject { described_class.make_tmpdir_name('test') }

    it 'returns a path based on Dir.tmpdir' do
      is_expected.to match(a_string_starting_with(Dir.tmpdir))
    end
  end

  describe '.canonical_path' do
    let(:path) { 'some_path' }

    context 'when running on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      context 'and the path does not exist' do
        before(:each) do
          allow(File).to receive(:exist?).with(path).and_return(false)
        end

        it 'raises a FatalError' do
          expect {
            described_class.canonical_path(path)
          }.to raise_error(PDK::CLI::FatalError, %r{cannot resolve a full path}i)
        end
      end

      context 'and the path exists' do
        before(:each) do
          allow(File).to receive(:exist?).with(path).and_return(true)
        end

        it 'calls Puppet::Util::Windows::File.get_long_pathname to resolve the absolute path' do
          expect(Puppet::Util::Windows::File).to receive(:get_long_pathname).with(path)

          described_class.canonical_path(path)
        end
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it 'calls File.expath_path to resolve the absolute path' do
        expect(File).to receive(:expand_path).with(path)

        described_class.canonical_path(path)
      end
    end
  end

  describe '.package_install?' do
    subject { described_class.package_install? }

    context 'when there is no version file', version_file: false do
      it { is_expected.to be false }
    end

    context 'when a version file is present', version_file: true do
      it { is_expected.to be true }
    end
  end

  describe '.development_mode?' do
    subject { described_class.development_mode? }

    context 'when running from a release' do
      before(:each) do
        allow(PDK::Util::Version).to receive(:git_ref).and_return(nil)
        stub_const('PDK::VERSION', '1.3.0')
      end

      it { is_expected.to be false }
    end

    context 'when running from a pre-release' do
      before(:each) do
        allow(PDK::Util::Version).to receive(:git_ref).and_return(nil)
        stub_const('PDK::VERSION', '1.3.0.pre')
      end

      it { is_expected.to be true }
    end

    context 'when running from git' do
      before(:each) do
        allow(PDK::Util::Version).to receive(:git_ref).and_return('abc')
      end

      it { is_expected.to be true }
    end
  end

  describe '.gem_install?' do
    subject { described_class.gem_install? }

    before(:each) do
      allow(described_class).to receive(:development_mode?).and_return(false)
    end

    context 'when there is no version file', version_file: false do
      it { is_expected.to be true }
    end

    context 'when a version file is present', version_file: true do
      it { is_expected.to be false }
    end

    context 'when a version file is present and in development mode is true', version_file: false do
      before(:each) do
        allow(described_class).to receive(:development_mode?).and_return(true)
      end

      it { is_expected.to be false }
    end
  end

  describe '.pdk_package_basedir' do
    subject { described_class.pdk_package_basedir }

    context 'when the PDK was installed from a gem', version_file: false do
      it 'raises a FatalError' do
        expect {
          described_class.pdk_package_basedir
        }.to raise_error(PDK::CLI::FatalError, %r{Package basedir requested for non-package install}i)
      end
    end

    context 'when the PDK was installed from a native package', version_file: true do
      it 'returns the directory where the version file is located' do
        is_expected.to eq(File.dirname(version_file))
      end
    end
  end

  describe '.package_cachedir' do
    subject { described_class.package_cachedir }

    context 'when the PDK was installed from a gem', version_file: false do
      it 'raises a FatalError' do
        expect {
          described_class.package_cachedir
        }.to raise_error(PDK::CLI::FatalError, %r{Package basedir requested for non-package install}i)
      end
    end

    context 'when the PDK was installed from a native package', version_file: true do
      it 'returns the path to the share/cache directory in the package' do
        is_expected.to eq(File.join(File.dirname(version_file), 'share', 'cache'))
      end
    end
  end

  describe '.cachedir' do
    subject { described_class.cachedir }

    context 'when running on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(ENV).to receive(:[]).with('LOCALAPPDATA').and_return('C:/Users/test')
      end

      it 'returns a path in the %LOCALAPPDATA% folder' do
        is_expected.to eq(File.join('C:/Users/test', 'PDK', 'cache'))
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(Dir).to receive(:home).and_return('/home/test')
      end

      it 'returns a path to a hidden folder in the users home directory' do
        is_expected.to eq(File.join('/home/test', '.pdk', 'cache'))
      end
    end
  end

  describe '.module_root' do
    subject { described_class.module_root }

    before(:each) do
      allow(described_class).to receive(:find_upwards).with('metadata.json').and_return(metadata_path)
    end

    context 'when a metadata.json file can be found upwards' do
      let(:metadata_path) { '/path/to/the/module/metadata.json' }

      it 'returns the path to the directory containing the metadata.json file' do
        is_expected.to eq(File.dirname(metadata_path))
      end
    end

    context 'when a metadata.json file could not be found' do
      let(:metadata_path) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '.find_first_json_in' do
    it 'returns JSON from start of a string' do
      text = '{"version":"3.6.0", "examples":[]}bar'
      expected = { 'version' => '3.6.0', 'examples' => [] }

      expect(described_class.find_first_json_in(text)).to eq(expected)
    end

    it 'returns JSON from the end of a string' do
      text = 'foo{"version":"3.6.0", "examples":[]}'
      expected = { 'version' => '3.6.0', 'examples' => [] }

      expect(described_class.find_first_json_in(text)).to eq(expected)
    end

    it 'returns JSON from the middle of a string' do
      text = 'foo{"version":"3.6.0", "examples":[]}bar'
      expected = { 'version' => '3.6.0', 'examples' => [] }

      expect(described_class.find_first_json_in(text)).to eq(expected)
    end

    it 'returns nil for invalid JSON in a string' do
      text = 'foo{"version"":"3.6.0", "examples":[]}bar'

      expect(described_class.find_first_json_in(text)).to be_nil
    end

    it 'returns nil for no JSON in a string' do
      text = 'foosomethingbar'

      expect(described_class.find_first_json_in(text)).to be_nil
    end

    it 'returns first JSON document from string with multiple valid docs' do
      text = '{"version": "3.6.0", "examples": []}{"version": "4.6.0", "examples": []}'
      expected = { 'version' => '3.6.0', 'examples' => [] }

      expect(described_class.find_first_json_in(text)).to eq(expected)
    end
  end

  describe '.find_all_json_in' do
    it 'returns array of JSON documents from string with multiple valid docs' do
      text = '{"version": "3.6.0", "examples": []}{"version": "4.6.0", "examples": []}'
      expected = [{ 'version' => '3.6.0', 'examples' => [] }, { 'version' => '4.6.0', 'examples' => [] }]

      expect(described_class.find_all_json_in(text)).to contain_exactly(*expected)
    end

    it 'returns an empty array when there are no valid JSON documents' do
      text = 'foo{"version"":"3.6.0", "examples":[]}bar'

      expect(described_class.find_all_json_in(text)).to eq([])
    end
  end

  describe '.default_template_url' do
    subject { described_class.default_template_url }

    before(:each) do
      allow(described_class).to receive(:puppetlabs_template_url).and_return('puppetlabs_template_url')
    end

    context 'when there is no template-url in answers file' do
      before(:each) do
        allow(PDK).to receive(:answers).and_return('template-url' => nil)
      end

      it 'returns puppetlabs template url' do
        is_expected.to eq('puppetlabs_template_url')
      end
    end

    context 'when the template-url in answers file matches current puppetlabs template' do
      before(:each) do
        allow(PDK).to receive(:answers).and_return('template-url' => 'puppetlabs_template_url')
      end

      it 'returns puppetlabs template url' do
        is_expected.to eq('puppetlabs_template_url')
      end
    end

    context 'when the template-url in answers file matches old puppetlabs template' do
      before(:each) do
        allow(PDK).to receive(:answers).and_return('template-url' => 'https://github.com/puppetlabs/pdk-module-template')
      end

      it 'returns puppetlabs template url' do
        is_expected.to eq('puppetlabs_template_url')
      end
    end

    context 'when the template-url in answers file is custom' do
      before(:each) do
        allow(PDK).to receive(:answers).and_return('template-url' => 'custom_template_url')
      end

      context 'and the template is a valid repo' do
        before(:each) do
          allow(PDK::Util::Git).to receive(:repo?).with('custom_template_url').and_return(true)
        end

        it 'returns custom url' do
          is_expected.to eq('custom_template_url')
        end
      end

      context 'and the template is not a valid repo' do
        before(:each) do
          allow(PDK::Util::Git).to receive(:repo?).with('custom_template_url').and_return(false)
          allow(PDK.answers).to receive(:update!).with('template-url' => nil)
        end

        it 'returns the puppetlabs template url' do
          expect(logger).to receive(:warn).with(a_string_matching(%r{using the default template}))
          is_expected.to eq('puppetlabs_template_url')
        end
      end
    end
  end

  describe '.default_template_ref' do
    subject { described_class.default_template_ref }

    before(:each) do
      allow(described_class).to receive(:puppetlabs_template_url).and_return('puppetlabs_template_url')
    end

    context 'with a custom template repo' do
      before(:each) do
        allow(described_class).to receive(:default_template_url).and_return('custom_template_url')
      end

      it 'returns origin/master' do
        is_expected.to eq('origin/master')
      end
    end

    context 'with the default template repo' do
      before(:each) do
        allow(described_class).to receive(:default_template_url).and_return('puppetlabs_template_url')
      end

      context 'not in development mode' do
        before(:each) do
          allow(described_class).to receive(:development_mode?).and_return(false)
        end

        it 'returns the built-in TEMPLATE_REF' do
          is_expected.to eq(PDK::TEMPLATE_REF)
        end
      end

      context 'in development mode' do
        before(:each) do
          allow(described_class).to receive(:development_mode?).and_return(true)
        end

        it 'returns origin/master' do
          is_expected.to eq('origin/master')
        end
      end
    end
  end
end

require 'spec_helper'
require 'pdk/util'

describe PDK::Util do
  let(:pdk_version) { '1.2.3' }
  let(:template_url) { 'metadata-templates' }
  let(:template_ref) { nil }
  let(:mock_metadata) do
    instance_double(
      PDK::Module::Metadata,
      data: {
        'pdk-version' => pdk_version,
        'template-url' => template_url,
        'template-ref' => template_ref,
      },
    )
  end

  shared_context 'with version file', version_file: true do
    let(:version_file) { File.join('path', 'to', 'the', 'version', 'file') }

    before(:each) do
      allow(PDK::Util::Version).to receive(:version_file).and_return(version_file)
    end
  end

  shared_context 'without version file', version_file: false do
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
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/something/deep/in/a/module').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to/something/deep/in/a/module').and_return('/path/to/something/deep/in/a')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/something/deep/in/a').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to/something/deep/in/a').and_return('/path/to/something/deep/in')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/something/deep/in').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to/something/deep/in').and_return('/path/to/something/deep')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/something/deep').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to/something/deep').and_return('/path/to/something')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to/something').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to/something').and_return('/path/to')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path/to').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path/to').and_return('/path')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/path').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/path').and_return('/')
      allow(PDK::Util::Filesystem).to receive(:directory?).with('/').and_return(true)
      allow(PDK::Util::Filesystem).to receive(:expand_path).with('..', '/').and_return('/')
      allow(PDK::Util::Filesystem).to receive(:expand_path).with(actual_start_dir).and_return(actual_start_dir)
      allow(PDK::Util::Filesystem).to receive(:file?).with(a_string_matching(%r{metadata\.json\Z})).and_return(false)
    end

    context 'when start_dir is nil' do
      before(:each) do
        allow(Dir).to receive(:pwd).and_return(actual_start_dir)
      end

      context 'and the target file exists' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/something/metadata.json').and_return(true)
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
          allow(PDK::Util::Filesystem).to receive(:file?).with('/path/to/something/metadata.json').and_return(true)
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
      expect(subject).to match(a_string_starting_with(Dir.tmpdir))
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
          allow(PDK::Util::Filesystem).to receive(:exist?).with(path).and_return(false)
        end

        it 'raises a FatalError' do
          expect {
            described_class.canonical_path(path)
          }.to raise_error(PDK::CLI::FatalError, %r{cannot resolve a full path}i)
        end
      end

      context 'and the path exists' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:exist?).with(path).and_return(true)
        end

        it 'calls Puppet::Util::Windows::File.get_long_pathname to resolve the absolute path' do
          expect(PDK::Util::Windows::File).to receive(:get_long_pathname).with(path)

          described_class.canonical_path(path)
        end
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
      end

      it 'calls File.expath_path to resolve the absolute path' do
        expect(PDK::Util::Filesystem).to receive(:expand_path).with(path)

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
        expect(subject).to eq(File.dirname(version_file))
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
        expect(subject).to eq(File.join(File.dirname(version_file), 'share', 'cache'))
      end
    end
  end

  describe '.cachedir' do
    subject { described_class.cachedir }

    context 'when running on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(PDK::Util::Env).to receive(:[]).with('LOCALAPPDATA').and_return('C:/Users/test')
      end

      it 'returns a path in the %LOCALAPPDATA% folder' do
        expect(subject).to eq(File.join('C:/Users/test', 'PDK', 'cache'))
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(Dir).to receive(:home).and_return('/home/test')
      end

      it 'returns a path to a hidden folder in the users home directory' do
        expect(subject).to eq(File.join('/home/test', '.pdk', 'cache'))
      end
    end
  end

  describe '.configdir' do
    subject { described_class.configdir }

    context 'when running on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
        allow(PDK::Util::Env).to receive(:[]).with('LOCALAPPDATA').and_return('C:/Users/test')
      end

      it 'returns a path in the %LOCALAPPDATA% folder' do
        expect(subject).to eq(File.join('C:/Users/test', 'PDK'))
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(Dir).to receive(:home).with(any_args).and_return('/home/test')
        allow(PDK::Util::Env).to receive(:fetch)
          .with('XDG_CONFIG_HOME', '/home/test/.config')
          .and_return('/xdg_home/test/.config')
      end

      it 'returns a path inside the users .config directory' do
        expect(subject).to eq('/xdg_home/test/.config/pdk')
      end
    end
  end

  describe '.system_configdir' do
    subject { described_class.system_configdir }

    let(:program_data) { 'C:/mock_program_data' }
    let(:windows_path) { File.join(program_data, 'PuppetLabs', 'PDK') }

    before(:each) do
      # Reset memoize values
      described_class.instance_variable_set(:@system_configdir, nil)
    end

    context 'when running on Windows' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(true)
      end

      context 'when ProgramData environment variable exists' do
        before(:each) do
          # ProgramData was added in Windows Vista
          allow(PDK::Util::Env).to receive(:[]).with('ProgramData').and_return(program_data)
          allow(PDK::Util::Env).to receive(:[]).with('AllUsersProfile').and_return(nil)
        end

        it 'returns a path in the Program Data directory' do
          expect(subject).to eq(windows_path)
        end
      end

      context 'when AllUsersProfile environment variable exists' do
        before(:each) do
          # AllUsersProfile was added in Windows 2000
          allow(PDK::Util::Env).to receive(:[]).with('ProgramData').and_return(nil)
          allow(PDK::Util::Env).to receive(:[]).with('AllUsersProfile').and_return(program_data)
        end

        it 'returns a path in the Program Data directory' do
          expect(subject).to eq(windows_path)
        end
      end
    end

    context 'when running on a POSIX host' do
      before(:each) do
        allow(Gem).to receive(:win_platform?).and_return(false)
        allow(Dir).to receive(:home).and_return('/home/test')
      end

      it 'returns a path inside the system opt directory' do
        expect(subject).to match(%r{\A/opt/})
      end
    end
  end

  describe '.module_fixtures_dir' do
    subject { described_class.module_fixtures_dir }

    before(:each) do
      allow(described_class).to receive(:find_upwards).with('metadata.json').and_return(metadata_path)
      allow(described_class).to receive(:in_module_root?).and_return(in_module_root)
    end

    context 'inside a module' do
      let(:metadata_path) { '/path/to/the/module/metadata.json' }
      let(:in_module_root) { true }

      it 'valid fixtures dir' do
        expect(subject).to eq(File.join(File.dirname(metadata_path), 'spec', 'fixtures'))
      end
    end

    context 'outside a module' do
      let(:metadata_path) { nil }
      let(:in_module_root) { false }

      it 'invalid fixtures dir' do
        expect(subject).to be_nil
      end
    end
  end

  describe '.module_root' do
    subject { described_class.module_root }

    before(:each) do
      allow(described_class).to receive(:find_upwards).with('metadata.json').and_return(metadata_path)
      allow(described_class).to receive(:in_module_root?).and_return(in_module_root)
    end

    context 'when a metadata.json file can be found upwards' do
      let(:metadata_path) { '/path/to/the/module/metadata.json' }
      let(:in_module_root) { true }

      it 'returns the path to the directory containing the metadata.json file' do
        expect(subject).to eq(File.dirname(metadata_path))
      end
    end

    context 'when a metadata.json file could not be found but module dirs can' do
      let(:metadata_path) { nil }
      let(:in_module_root) { true }

      it { is_expected.to eq(Dir.pwd) }
    end

    context 'when a metadata.json file and module dirs could not be found' do
      let(:metadata_path) { nil }
      let(:in_module_root) { false }

      it { is_expected.to be_nil }
    end
  end

  describe '.in_module_root?' do
    subject { described_class.module_root }

    # We use NUL here because that should never be a valid directory name. But it will work with RSpec mocking.
    let(:test_path) { '\x00path/test' }

    before(:each) do
      allow(PDK::Util::Filesystem).to receive(:directory?).and_call_original
    end

    # Directories which indicate a module root
    ['manifests', 'lib/puppet', 'lib/puppet_x', 'lib/facter', 'tasks', 'facts.d', 'functions', 'types'].each do |testcase|
      it "detects #{testcase} as being in the root of a module" do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.in_module_root?(test_path)).to eq(true)
      end
    end

    # Directories which do not indicate a module root
    ['lib', 'Boltdir', 'puppet'].each do |testcase|
      it "detects #{testcase} as not being in the root of a module" do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(File.join(test_path, testcase)).and_return(true)
        expect(described_class.in_module_root?(test_path)).to eq(false)
      end
    end

    it 'detects metadata.json within the folder and determines that it is the root of a module' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(File.join(test_path, 'metadata.json')).and_return(true)
      expect(described_class.in_module_root?(test_path)).to eq(true)
    end

    it 'uses the current directory if a directory is not specified' do
      expect(PDK::Util::Filesystem).to receive(:directory?) { |path| expect(path).to start_with(Dir.pwd) }.at_least(:once)
      described_class.in_module_root?
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

    it 'returns nil for an unbalanced invalid JSON object' do
      text = 'foo{{bar}'

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

    context 'with balanced nested JSON fragment' do
      it 'returns largest valid JSON document' do
        text = '{"version": "3.6.0", "content": "{\"nested\": \"fragment\"}"}'
        expected = { 'version' => '3.6.0', 'content' => '{"nested": "fragment"}' }

        expect(described_class.find_first_json_in(text)).to eq(expected)
      end
    end

    context 'with unbalanced nested JSON fragment' do
      it 'returns largest valid JSON document' do
        text = '{"version": "3.6.0", "content": "{{\"nested\": \"fragment\"}"}'
        expected = { 'version' => '3.6.0', 'content' => '{{"nested": "fragment"}' }

        expect(described_class.find_first_json_in(text)).to eq(expected)
      end
    end
  end

  describe '.find_all_json_in' do
    it 'returns array of JSON documents from string with multiple valid docs' do
      text = '{"version": "3.6.0", "examples": []}{"version": "4.6.0", "examples": []}'
      expected = [{ 'version' => '3.6.0', 'examples' => [] }, { 'version' => '4.6.0', 'examples' => [] }]

      expect(described_class.find_all_json_in(text)).to match_array(expected)
    end

    it 'returns an empty array when there are no valid JSON documents' do
      text = 'foo{"version"":"3.6.0", "examples":[]}bar'

      expect(described_class.find_all_json_in(text)).to eq([])
    end
  end

  describe 'module_metadata' do
    subject(:result) { described_class.module_metadata }

    before(:each) do
      allow(described_class).to receive(:module_root).and_return(EMPTY_MODULE_ROOT)
      allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(described_class.module_root, 'metadata.json')).and_return(mock_metadata)
    end

    context 'when the metadata.json can be read' do
      it 'returns the metadata object' do
        expect(subject).to eq(mock_metadata.data)
      end
    end

    context 'when the metadata.json can not be read' do
      before(:each) do
        allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(described_class.module_root, 'metadata.json')).and_raise(ArgumentError, 'some error')
      end

      it 'raises an ExitWithError exception' do
        expect { -> { result }.call }.to raise_error(ArgumentError, %r{some error}i)
      end
    end
  end

  describe 'module_pdk_compatible?' do
    subject(:result) { described_class.module_pdk_compatible? }

    context 'is compatible' do
      before(:each) do
        allow(described_class).to receive(:module_metadata).and_return(mock_metadata.data)
      end

      it { is_expected.to be true }
    end

    context 'is not compatible' do
      before(:each) do
        allow(described_class).to receive(:module_metadata).and_return({})
      end

      it { is_expected.to be false }
    end
  end

  describe 'module_pdk_version' do
    subject(:result) { described_class.module_pdk_version }

    let(:module_metadata) { {} }

    before(:each) do
      allow(described_class).to receive(:module_metadata).and_return(module_metadata)
    end

    context 'is nil' do
      let(:module_metadata) { { 'pdk-version' => nil } }

      it { is_expected.to be_nil }
    end

    context 'is an empty string' do
      let(:module_metadata) { { 'pdk-version' => '' } }

      it { is_expected.to be_nil }
    end

    context 'is in metadata' do
      let(:module_metadata) { mock_metadata.data }

      it { is_expected.to match(pdk_version) }
    end

    context 'is not in metadata' do
      it { is_expected.to be_nil }
    end

    context 'if there is a problem reading the metadata.json file' do
      before(:each) do
        allow(described_class).to receive(:module_metadata).and_raise(ArgumentError, 'some error')
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'deep_duplicate' do
    it 'deeply copies arrays' do
      original = ['abc', 1, nil, ['foo', { 'bar' => 'baz' }], 1.0]
      copy = described_class.deep_duplicate(original)

      expect(copy).to eq(original)
      expect(copy).not_to be(original)
      # Nested arrays
      expect(copy[3]).to eq(original[3])
      expect(copy[3]).not_to be(original[3])
      # Nested hashes
      expect(copy[3][1]).to eq(original[3][1])
      expect(copy[3][1]).not_to be(original[3][1])
    end
  end
end

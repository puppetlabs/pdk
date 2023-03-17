require 'spec_helper'
require 'pdk/module/build'
require 'pathspec'

describe PDK::Module::Build do
  subject { described_class.new(initialize_options) }

  let(:initialize_options) { {} }
  let(:root_dir) { Gem.win_platform? ? 'C:/' : '/' }

  shared_context 'with mock metadata' do
    let(:mock_metadata) { PDK::Module::Metadata.new('name' => 'my-module') }

    before(:each) do
      allow(PDK::Module::Metadata).to receive(:from_file).with(anything).and_return(mock_metadata)
    end
  end

  describe '.invoke' do
    it 'creates a new PDK::Module::Build instance and calls #build' do
      build_double = instance_double(described_class, build: true)

      expect(described_class).to receive(:new).with(module_dir: 'test').and_return(build_double)
      expect(build_double).to receive(:build)

      described_class.invoke(module_dir: 'test')
    end
  end

  describe '#initialize' do
    before(:each) do
      allow(Dir).to receive(:pwd).and_return(pwd)
    end

    let(:pwd) { File.join(root_dir, 'path', 'to', 'module') }

    context 'by default' do
      it 'uses the current working directory as the module directory' do
        expect(subject).to have_attributes(module_dir: pwd)
      end

      it 'places the built packages in the pkg directory in the module' do
        expect(subject).to have_attributes(target_dir: File.join(pwd, 'pkg'))
      end
    end

    context 'if module_dir has been customised' do
      let(:initialize_options) do
        {
          module_dir: File.join(root_dir, 'some', 'other', 'module'),
        }
      end

      it 'uses the provided path as the module directory' do
        expect(subject).to have_attributes(module_dir: initialize_options[:module_dir])
      end

      it 'places the built packages in the pkg directory in the module' do
        expect(subject).to have_attributes(target_dir: File.join(initialize_options[:module_dir], 'pkg'))
      end
    end

    context 'if target_dir has been customised' do
      let(:initialize_options) do
        {
          'target-dir': File.join(root_dir, 'tmp'),
        }
      end

      it 'uses the current working directory as the module directory' do
        expect(subject).to have_attributes(module_dir: pwd)
      end

      it 'places the built packages in the provided path' do
        expect(subject).to have_attributes(target_dir: initialize_options[:'target-dir'])
      end
    end

    context 'if both module_dir and target_dir have been customised' do
      let(:initialize_options) do
        {
          'target-dir': File.join(root_dir, 'var', 'cache'),
          module_dir: File.join(root_dir, 'tmp', 'git', 'my-module'),
        }
      end

      it 'uses the provided module_dir path as the module directory' do
        expect(subject).to have_attributes(module_dir: initialize_options[:module_dir])
      end

      it 'places the built packages in the provided target_dir path' do
        expect(subject).to have_attributes(target_dir: initialize_options[:'target-dir'])
      end
    end
  end

  describe '#metadata' do
    subject { described_class.new.metadata }

    include_context 'with mock metadata'

    it { is_expected.to be_a(Hash) }
    it { is_expected.to include('name' => 'my-module', 'version' => '0.1.0') }
  end

  describe '#release_name' do
    subject { described_class.new.release_name }

    include_context 'with mock metadata'

    it { is_expected.to eq('my-module-0.1.0') }
  end

  describe '#package_file' do
    subject { described_class.new('target-dir': target_dir).package_file }

    let(:target_dir) { File.join(root_dir, 'tmp') }

    include_context 'with mock metadata'

    it { is_expected.to eq(File.join(target_dir, 'my-module-0.1.0.tar.gz')) }
  end

  describe '#build_dir' do
    subject { described_class.new('target-dir': target_dir).build_dir }

    let(:target_dir) { File.join(root_dir, 'tmp') }

    include_context 'with mock metadata'

    it { is_expected.to eq(File.join(target_dir, 'my-module-0.1.0')) }
  end

  describe '#stage_module_in_build_dir' do
    let(:instance) { described_class.new(module_dir: module_dir) }
    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }

    before(:each) do
      allow(instance).to receive(:ignored_files).and_return(PathSpec.new("/spec/\n"))
      allow(Find).to receive(:find).with(module_dir).and_yield(found_file)
    end

    after(:each) do
      instance.stage_module_in_build_dir
    end

    context 'when it finds a non-ignored path' do
      let(:found_file) { File.join(module_dir, 'metadata.json') }

      it 'stages the path into the build directory' do
        expect(instance).to receive(:stage_path).with(found_file)
      end
    end

    context 'when it finds an ignored path' do
      let(:found_file) { File.join(module_dir, 'spec', 'spec_helper.rb') }

      it 'does not stage the path' do
        expect(Find).to receive(:prune)
        expect(instance).not_to receive(:stage_path).with(found_file)
      end
    end

    context 'when it finds the module directory itself' do
      let(:found_file) { module_dir }

      it 'does not stage the path' do
        expect(instance).not_to receive(:stage_path).with(module_dir)
      end
    end
  end

  describe '#stage_path' do
    let(:instance) { described_class.new(module_dir: module_dir) }
    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }
    let(:path_to_stage) { File.join(module_dir, 'test') }
    let(:path_in_build_dir) { File.join(module_dir, 'pkg', release_name, 'test') }
    let(:release_name) { 'my-module-0.0.1' }

    before(:each) do
      allow(instance).to receive(:release_name).and_return(release_name)
    end

    context 'when the path contains non-ASCII characters' do
      RSpec.shared_examples 'a failing path' do |relative_path|
        let(:path) do
          File.join(module_dir, relative_path).force_encoding(Encoding.find('filesystem')).encode('utf-8', invalid: :replace)
        end

        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:directory?).with(path).and_return(true)
          allow(PDK::Util::Filesystem).to receive(:symlink?).with(path).and_return(false)
          allow(PDK::Util::Filesystem).to receive(:cp).with(path, anything, anything).and_return(true)
        end

        it 'exits with an error' do
          expect {
            instance.stage_path(path)
          }.to raise_error(PDK::CLI::ExitWithError, %r{can only include ASCII characters})
        end
      end

      include_examples 'a failing path', "strange_unicode_\u{000100}"
      include_examples 'a failing path', "\300\271to"
    end

    context 'when the path is a directory' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path_to_stage).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:stat).with(path_to_stage).and_return(instance_double(File::Stat, mode: 0o100755))
      end

      it 'creates the directory in the build directory' do
        expect(PDK::Util::Filesystem).to receive(:mkdir_p).with(path_in_build_dir, mode: 0o100755)
        instance.stage_path(path_to_stage)
      end
    end

    context 'when the path is a symlink' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path_to_stage).and_return(false)
        allow(PDK::Util::Filesystem).to receive(:symlink?).with(path_to_stage).and_return(true)
      end

      it 'warns the user about the symlink and skips over it' do
        expect(instance).to receive(:warn_symlink).with(path_to_stage)
        expect(PDK::Util::Filesystem).not_to receive(:mkdir_p).with(any_args)
        expect(PDK::Util::Filesystem).not_to receive(:cp).with(any_args)
        instance.stage_path(path_to_stage)
      end
    end

    context 'when the path is a regular file' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with(path_to_stage).and_return(false)
        allow(PDK::Util::Filesystem).to receive(:symlink?).with(path_to_stage).and_return(false)
      end

      it 'copies the file into the build directory, preserving the permissions' do
        expect(PDK::Util::Filesystem).to receive(:cp).with(path_to_stage, path_in_build_dir, preserve: true)
        instance.stage_path(path_to_stage)
      end

      context 'when the path is too long' do
        let(:path_to_stage) { File.join(*['thing'] * 30) }

        it 'exits with an error' do
          expect {
            instance.stage_path(path_to_stage)
          }.to raise_error(PDK::CLI::ExitWithError)
        end
      end
    end
  end

  describe '#path_too_long?' do
    subject(:instance) { described_class.new }

    good_paths = [
      File.join('a' * 155, 'b' * 100),
      File.join('a' * 151, *['qwer'] * 19, 'bla'),
      File.join('/', 'a' * 49, 'b' * 50),
      File.join('a' * 49, "#{'b' * 50}x"),
      File.join("#{'a' * 49}x", 'b' * 50),
    ]

    bad_paths = {
      File.join('a' * 152, 'b' * 11, 'c' * 93) => %r{longer than 256}i,
      File.join('a' * 152, 'b' * 10, 'c' * 92) => %r{could not be split}i,
      File.join('a' * 162, 'b' * 10) => %r{could not be split}i,
      File.join('a' * 10, 'b' * 110) => %r{could not be split}i,
      'a' * 114 => %r{could not be split}i,
    }

    good_paths.each do |path|
      context "when checking '#{path}'" do
        it 'does not raise an error' do
          expect { instance.validate_ustar_path!(path) }.not_to raise_error
        end
      end
    end

    bad_paths.each do |path, err|
      context "when checking '#{path}'" do
        it 'raises an ArgumentError' do
          expect { instance.validate_ustar_path!(path) }.to raise_error(ArgumentError, err)
        end
      end
    end
  end

  describe '#validate_path_encoding!' do
    subject(:instance) { described_class.new }

    context 'when passed a path containing only ASCII characters' do
      it 'does not raise an error' do
        expect {
          instance.validate_path_encoding!(File.join('path', 'to', 'file'))
        }.not_to raise_error
      end
    end

    context 'when passed a path containing non-ASCII characters' do
      it 'raises an error' do
        expect {
          instance.validate_path_encoding!(File.join('path', "\330\271to", 'file'))
        }.to raise_error(ArgumentError, %r{can only include ASCII characters})
      end
    end
  end

  describe '#ignored_path?' do
    let(:instance) { described_class.new(module_dir: module_dir) }
    let(:ignore_patterns) do
      [
        '/vendor/',
        'foo',
      ]
    end
    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }

    before(:each) do
      allow(instance).to receive(:ignored_files).and_return(PathSpec.new(ignore_patterns.join("\n")))
    end

    it 'returns false for paths not matched by the patterns' do
      expect(instance).not_to be_ignored_path(File.join(module_dir, 'bar'))
    end

    it 'returns true for paths matched by the patterns' do
      expect(instance).to be_ignored_path(File.join(module_dir, 'foo'))
    end

    it 'returns true for children of ignored parent directories' do
      expect(instance).to be_ignored_path(File.join(module_dir, 'vendor', 'test'))
    end
  end

  describe '#ignore_file' do
    subject { described_class.new(module_dir: module_dir).ignore_file }

    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }
    let(:possible_files) do
      [
        '.pdkignore',
        '.pmtignore',
        '.gitignore',
      ]
    end
    let(:available_files) { [] }

    before(:each) do
      available_files.each do |file|
        file_path = File.join(module_dir, file)

        allow(PDK::Util::Filesystem).to receive(:file?).with(file_path).and_return(true)
        allow(PDK::Util::Filesystem).to receive(:readable?).with(file_path).and_return(true)
      end

      (possible_files - available_files).each do |file|
        file_path = File.join(module_dir, file)

        allow(PDK::Util::Filesystem).to receive(:file?).with(file_path).and_return(false)
        allow(PDK::Util::Filesystem).to receive(:readable?).with(file_path).and_return(false)
      end
    end

    context 'when none of the possible ignore files are present' do
      it { is_expected.to be_nil }
    end

    context 'when .gitignore is present' do
      let(:available_files) { ['.gitignore'] }

      it 'returns the path to the .gitignore file' do
        expect(subject).to eq(File.join(module_dir, '.gitignore'))
      end

      context 'and .pmtignore is present' do
        let(:available_files) { ['.gitignore', '.pmtignore'] }

        it 'returns the path to the .pmtignore file' do
          expect(subject).to eq(File.join(module_dir, '.pmtignore'))
        end

        context 'and .pdkignore is present' do
          let(:available_files) { possible_files }

          it 'returns the path to the .pdkignore file' do
            expect(subject).to eq(File.join(module_dir, '.pdkignore'))
          end
        end
      end
    end
  end

  describe '#ignored_files' do
    subject { instance.ignored_files }

    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }
    let(:instance) { described_class.new(module_dir: module_dir) }

    before(:each) do
      allow(File).to receive(:realdirpath) { |path| path }
    end

    context 'when no ignore file is present in the module' do
      before(:each) do
        allow(instance).to receive(:ignore_file).and_return(nil)
      end

      it 'returns a PathSpec object with the target dir' do
        expect(subject).to be_a(PathSpec)
        expect(subject).not_to be_empty
        expect(subject).to match('pkg/')
      end
    end

    context 'when an ignore file is present in the module' do
      before(:each) do
        ignore_file_path = File.join(module_dir, '.pdkignore')
        ignore_file_content = "/vendor/\n"

        allow(instance).to receive(:ignore_file).and_return(ignore_file_path)
        allow(PDK::Util::Filesystem).to receive(:read_file).with(ignore_file_path, anything).and_return(ignore_file_content)
      end

      it 'returns a PathSpec object populated by the ignore file' do
        expect(subject).to be_a(PathSpec)
        expect(subject).to have_attributes(specs: array_including(an_instance_of(PathSpec::GitIgnoreSpec)))
      end
    end
  end
end

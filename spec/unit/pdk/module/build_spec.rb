require 'spec_helper'
require 'pdk/module/build'

describe PDK::Module::Build do
  subject { described_class.new(initialize_options) }

  before(:each) do
    allow(PDK::Test::Unit).to receive(:tear_down)
  end

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
        is_expected.to have_attributes(module_dir: pwd)
      end

      it 'places the built packages in the pkg directory in the module' do
        is_expected.to have_attributes(target_dir: File.join(pwd, 'pkg'))
      end
    end

    context 'if module_dir has been customised' do
      let(:initialize_options) do
        {
          module_dir: File.join(root_dir, 'some', 'other', 'module'),
        }
      end

      it 'uses the provided path as the module directory' do
        is_expected.to have_attributes(module_dir: initialize_options[:module_dir])
      end

      it 'places the built packages in the pkg directory in the module' do
        is_expected.to have_attributes(target_dir: File.join(initialize_options[:module_dir], 'pkg'))
      end
    end

    context 'if target_dir has been customised' do
      let(:initialize_options) do
        {
          :'target-dir' => File.join(root_dir, 'tmp'),
        }
      end

      it 'uses the current working directory as the module directory' do
        is_expected.to have_attributes(module_dir: pwd)
      end

      it 'places the built packages in the provided path' do
        is_expected.to have_attributes(target_dir: initialize_options[:'target-dir'])
      end
    end

    context 'if both module_dir and target_dir have been customised' do
      let(:initialize_options) do
        {
          :'target-dir' => File.join(root_dir, 'var', 'cache'),
          module_dir: File.join(root_dir, 'tmp', 'git', 'my-module'),
        }
      end

      it 'uses the provided module_dir path as the module directory' do
        is_expected.to have_attributes(module_dir: initialize_options[:module_dir])
      end

      it 'places the built packages in the provided target_dir path' do
        is_expected.to have_attributes(target_dir: initialize_options[:'target-dir'])
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
    subject { described_class.new(:'target-dir' => target_dir).package_file }

    let(:target_dir) { File.join(root_dir, 'tmp') }

    include_context 'with mock metadata'

    it { is_expected.to eq(File.join(target_dir, 'my-module-0.1.0.tar.gz')) }
  end

  describe '#build_dir' do
    subject { described_class.new(:'target-dir' => target_dir).build_dir }

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

    after(:each) do
      instance.stage_path(path_to_stage)
    end

    context 'when the path is a directory' do
      before(:each) do
        allow(File).to receive(:directory?).with(path_to_stage).and_return(true)
        allow(File).to receive(:stat).with(path_to_stage).and_return(instance_double(File::Stat, mode: 0o100755))
      end

      it 'creates the directory in the build directory' do
        expect(FileUtils).to receive(:mkdir_p).with(path_in_build_dir, mode: 0o100755)
      end
    end

    context 'when the path is a symlink' do
      before(:each) do
        allow(File).to receive(:directory?).with(path_to_stage).and_return(false)
        allow(File).to receive(:symlink?).with(path_to_stage).and_return(true)
      end

      it 'warns the user about the symlink and skips over it' do
        expect(instance).to receive(:warn_symlink).with(path_to_stage)
        expect(FileUtils).not_to receive(:mkdir_p).with(any_args)
        expect(FileUtils).not_to receive(:cp).with(any_args)
      end
    end

    context 'when the path is a regular file' do
      before(:each) do
        allow(File).to receive(:directory?).with(path_to_stage).and_return(false)
        allow(File).to receive(:symlink?).with(path_to_stage).and_return(false)
      end

      it 'copies the file into the build directory, preserving the permissions' do
        expect(FileUtils).to receive(:cp).with(path_to_stage, path_in_build_dir, preserve: true)
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
      expect(instance.ignored_path?(File.join(module_dir, 'bar'))).to be_falsey
    end

    it 'returns true for paths matched by the patterns' do
      expect(instance.ignored_path?(File.join(module_dir, 'foo'))).to be_truthy
    end

    it 'returns true for children of ignored parent directories' do
      expect(instance.ignored_path?(File.join(module_dir, 'vendor', 'test'))).to be_truthy
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

        allow(File).to receive(:file?).with(file_path).and_return(true)
        allow(File).to receive(:readable?).with(file_path).and_return(true)
      end

      (possible_files - available_files).each do |file|
        file_path = File.join(module_dir, file)

        allow(File).to receive(:file?).with(file_path).and_return(false)
        allow(File).to receive(:readable?).with(file_path).and_return(false)
      end
    end

    context 'when none of the possible ignore files are present' do
      it { is_expected.to be_nil }
    end

    context 'when .gitignore is present' do
      let(:available_files) { ['.gitignore'] }

      it 'returns the path to the .gitignore file' do
        is_expected.to eq(File.join(module_dir, '.gitignore'))
      end

      context 'and .pmtignore is present' do
        let(:available_files) { ['.gitignore', '.pmtignore'] }

        it 'returns the path to the .pmtignore file' do
          is_expected.to eq(File.join(module_dir, '.pmtignore'))
        end

        context 'and .pdkignore is present' do
          let(:available_files) { possible_files }

          it 'returns the path to the .pdkignore file' do
            is_expected.to eq(File.join(module_dir, '.pdkignore'))
          end
        end
      end
    end
  end

  describe '#ignored_files' do
    subject { instance.ignored_files }

    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }
    let(:instance) { described_class.new(module_dir: module_dir) }

    context 'when no ignore file is present in the module' do
      before(:each) do
        allow(Find).to receive(:find).with(module_dir).and_return([File.join(module_dir, 'pkg')])
        allow(instance).to receive(:ignore_file).and_return(nil)
      end

      it 'returns a PathSpec object with the target dir' do
        is_expected.to be_a(PathSpec)
        is_expected.not_to be_empty
        is_expected.to match('pkg/')
      end
    end

    context 'when an ignore file is present in the module' do
      before(:each) do
        ignore_file_path = File.join(module_dir, '.pdkignore')
        ignore_file_content = StringIO.new "/vendor/\n"

        allow(instance).to receive(:ignore_file).and_return(ignore_file_path)
        allow(File).to receive(:open).with(ignore_file_path, 'rb:UTF-8').and_return(ignore_file_content)
        allow(Find).to receive(:find).with(module_dir).and_return([File.join(module_dir, 'pkg')])
      end

      it 'returns a PathSpec object populated by the ignore file' do
        is_expected.to be_a(PathSpec)
        is_expected.to have_attributes(specs: array_including(an_instance_of(PathSpec::GitIgnoreSpec)))
      end
    end
  end

  describe '#cleanup_module' do
    subject(:instance) { described_class.new(module_dir: module_dir) }

    let(:module_dir) { File.join(root_dir, 'tmp', 'my-module') }

    after(:each) do
      instance.cleanup_module
    end

    it 'ensures the rake binstub is present before cleaning up spec fixtures' do
      expect(PDK::Util::Bundler).to receive(:ensure_bundle!).ordered
      expect(PDK::Util::Bundler).to receive(:ensure_binstubs!).with('rake').ordered
      expect(PDK::Test::Unit).to receive(:tear_down).ordered
    end
  end
end

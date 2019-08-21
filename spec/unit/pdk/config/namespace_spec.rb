require 'spec_helper'

describe PDK::Config::Namespace do
  subject(:config) { described_class.new('config', config_options) }

  let(:config_options) { {} }

  shared_context :with_a_nested_namespace do |name|
    before(:each) do
      config.namespace(name)
    end
  end

  shared_context :with_a_mounted_file do |name|
    before(:each) do
      path = File.expand_path(File.join('path', 'to', name))
      allow(PDK::Util::Filesystem).to receive(:read_file).with(path, anything)
      allow(PDK::Util::Filesystem).to receive(:write_file).with(path, anything)
      allow(PDK::Util::Filesystem).to receive(:mkdir_p)

      config.mount(name, PDK::Config::JSON.new(file: path))
    end
  end

  shared_context :with_a_mounted_file_with_content do |name, content|
    before(:each) do
      path = File.expand_path(File.join('path', 'to', name))
      allow(PDK::Util::Filesystem).to receive(:read_file).with(path).and_return(content)
      allow(PDK::Util::Filesystem).to receive(:file?).and_call_original
      allow(PDK::Util::Filesystem).to receive(:file?).with(path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:write_file).with(path, anything)
      allow(PDK::Util::Filesystem).to receive(:mkdir_p)

      config.mount(name, PDK::Config::JSON.new(file: path))
    end
  end

  describe '#load_data' do
    context 'when creating a namespace from a file' do
      subject(:new_namespace) { described_class.new('new_namespace', file: path) }

      let(:path) { File.expand_path(File.join('path', 'to', 'my', 'config', 'file')) }

      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:file?).with(path).and_return(true)
      end

      context 'when the file is deleted mid-read' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:read_file).with(path).and_raise(Errno::ENOENT, 'error')
        end

        it 'raises PDK::Config::LoadError' do
          expect { new_namespace[:test] }.to raise_error(PDK::Config::LoadError, %r{error})
        end
      end

      context 'when the file is unreadable' do
        before(:each) do
          allow(PDK::Util::Filesystem).to receive(:read_file).with(path).and_raise(Errno::EACCES)
        end

        it 'raises PDK::Config::LoadError' do
          expect {
            new_namespace[:test]
          }.to raise_error(PDK::Config::LoadError, "Unable to open #{path} for reading")
        end
      end
    end
  end

  describe '#[]' do
    before(:each) do
      config[:foo] = 'bar'
    end

    it 'can access values with either Symbol or String keys' do
      expect([config[:foo], config['foo']]).to all(eq('bar'))
    end

    it 'can access arbitrarily deep values' do
      expect(config[:bar][:baz]).to eq({})
    end

    it 'does not save values when reading defaults' do
      expect(config).to receive(:save_data).never # rubocop:disable RSpec/SubjectStub This is an expectation, not a stub
      expect(config[:missing]).to eq({})
    end

    context 'when persistent_defaults is true' do
      let(:config_options) { { persistent_defaults: true } }

      before(:each) do
        # Add a value with a default value
        config.value('spec_test') do
          default_to { 'spec_default' }
        end
      end

      it 'saves default values to disk' do
        expect(config).to receive(:save_data).once # rubocop:disable RSpec/SubjectStub This is an expectation, not a stub
        expect(config[:spec_test]).to eq('spec_default')
      end
    end

    context 'when persistent_defaults is false' do
      let(:config_options) { { persistent_defaults: false } }

      before(:each) do
        # Add a value with a default value
        config.value('spec_test') do
          default_to { 'spec_default' }
        end
      end

      it 'does not save default values to disk' do
        expect(config).to receive(:save_data).never # rubocop:disable RSpec/SubjectStub This is an expectation, not a stub
        expect(config[:spec_test]).to eq('spec_default')
      end
    end
  end

  describe '#fetch' do
    before(:each) do
      config[:foo] = 'bar'
    end

    it 'can access values with either Symbol or String keys' do
      expect([config.fetch(:foo, 'default'), config.fetch('foo', 'default')]).to all(eq('bar'))
    end

    it 'will return the specified default value for unknown values' do
      expect([config.fetch(:missing, 'default'), config.fetch('missing', 'default')]).to all(eq('default'))
    end

    it 'does not save values when using the default' do
      expect(config).to receive(:save_data).never # rubocop:disable RSpec/SubjectStub This is an expectation, not a stub
      config.fetch(:missing, 'default')
    end
  end

  describe '#resolve' do
    let(:config_options) { { persistent_defaults: false } }

    include_context :with_a_mounted_file_with_content, 'mounted', '{"setting1": "value1"}'

    before(:each) do
      # Add a value with a default value
      config.value('spec_test') do
        default_to { 'spec_default' }
      end
      # The resolver should not trigger any saves unless persistent_defaults is set to true
      expect(PDK::Util::Filesystem).to receive(:write_file).never
    end

    context 'with an empty filter' do
      let(:filter) { nil }

      it 'resolves all settings' do
        result = config.resolve(filter)
        expect(result.count).to eq(2)
        expect(result['config.spec_test']).to eq('spec_default')
        expect(result['config.mounted.setting1']).to eq('value1')
      end
    end

    context 'with a setting name' do
      let(:filter) { 'config.spec_test' }

      it 'resolves only one setting' do
        result = config.resolve(filter)
        expect(result.count).to eq(1)
        expect(result['config.spec_test']).to eq('spec_default')
      end
    end

    context 'with a tree name' do
      let(:filter) { 'config.mounted' }

      it 'resolves only settings in the tree' do
        result = config.resolve(filter)
        expect(result.count).to eq(1)
        expect(result['config.mounted.setting1']).to eq('value1')
      end
    end

    context 'with a name that cannot be resolved' do
      let(:filter) { 'does.not.exist' }

      it 'returns an empty hash' do
        result = config.resolve(filter)
        expect(result).to eq({})
      end
    end
  end

  describe '#namespace' do
    before(:each) do
      config.namespace('test')
    end

    it 'mounts a new Namespace at the specified name' do
      expect(config['test']).to be_a(described_class)
    end

    it 'sets the name of the new Namespace' do
      expect(config['test'].name).to eq('config.test')
    end

    it 'sets the parent of the new Namespace' do
      expect(config['test'].parent).to eq(config)
    end

    it 'does not set a file for the new Namespace' do
      expect(config['test'].file).to be_nil
    end
  end

  describe '#mount' do
    let(:new_namespace) { described_class.new }

    before(:each) do
      config.mount('test_mount', new_namespace)
    end

    it 'mounts the provided namespace at the specified name' do
      expect(config['test_mount']).to eq(new_namespace)
    end

    it 'sets the name of the provided namespace' do
      expect(config['test_mount'].name).to eq('config.test_mount')
    end

    it 'sets the parent of the provided namespace' do
      expect(config['test_mount'].parent).to eq(config)
    end
  end

  describe '#value' do
    before(:each) do
      config.value('my_value') { default_to { 'foo' } }
    end

    it 'configures the rules for a new value in a namespace' do
      expect(config['my_value']).to eq('foo')
    end
  end

  describe '#name' do
    include_context :with_a_nested_namespace, 'nested'
    include_context :with_a_mounted_file, 'mounted'

    context 'on a root namespace' do
      it 'returns the name of the namespace' do
        expect(config.name).to eq('config')
      end
    end

    context 'on a nested namespace' do
      it 'returns the names of the parent and child namespaces as a dotted heirarchy' do
        expect(config['nested'].name).to eq('config.nested')
      end
    end

    context 'on a mounted file' do
      it 'returns the names of the parent and mounted file as a dotted heirarchy' do
        expect(config['mounted'].name).to eq('config.mounted')
      end
    end
  end

  describe '#to_h' do
    include_context :with_a_nested_namespace, 'nested'
    include_context :with_a_mounted_file, 'mounted'

    before(:each) do
      config['in_root'] = true
      config['nested']['value'] = 'is saved too'
      config['mounted']['value'] = 'is saved to a different file'
    end

    it 'includes the contents of namespaces' do
      expect(config.to_h).to include('nested' => { 'value' => 'is saved too' })
    end

    it 'includes values in its own namespace' do
      expect(config.to_h).to include('in_root' => true)
    end

    it 'does not include the values in mounted files' do
      expect(config.to_h).not_to have_key('mounted')
    end
  end

  describe '#child_namespace?' do
    include_context :with_a_nested_namespace, 'nested'
    include_context :with_a_mounted_file, 'mounted'

    context 'on a root namespace' do
      it 'returns false' do
        expect(config.child_namespace?).to be_falsey
      end
    end

    context 'on a nested namespace' do
      it 'returns true' do
        expect(config['nested'].child_namespace?).to be_truthy
      end
    end

    context 'on a mounted file' do
      it 'returns true' do
        expect(config['mounted'].child_namespace?).to be_truthy
      end
    end
  end

  describe '#include_in_parent?' do
    include_context :with_a_nested_namespace, 'nested'
    include_context :with_a_mounted_file, 'mounted'

    context 'on a root namespace' do
      it 'returns false' do
        expect(config.include_in_parent?).to be_falsey
      end
    end

    context 'on a nested namespace' do
      it 'returns true' do
        expect(config['nested'].include_in_parent?).to be_truthy
      end
    end

    context 'on a mounted file' do
      it 'returns true' do
        expect(config['mounted'].include_in_parent?).to be_falsey
      end
    end
  end
end

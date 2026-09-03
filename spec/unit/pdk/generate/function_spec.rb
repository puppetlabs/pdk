require 'spec_helper'
require 'pdk/generate/function'

describe PDK::Generate::Function do
  subject(:generator) { described_class.new(context, given_name, options) }

  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_dir) { '/tmp/test_module' }
  let(:module_name) { 'test_module' }
  let(:options) { { type: 'v4' } }
  let(:given_name) { 'test_module::my_func' }

  before do
    allow(PDK::Util).to receive(:module_metadata).with(module_dir).and_return('name' => "test_author-#{module_name}")
  end

  it 'inherits from PuppetObject' do
    expect(generator).to be_a(PDK::Generate::PuppetObject)
  end

  describe '#initialize' do
    context 'when the given name already starts with the module name' do
      let(:given_name) { 'test_module::my_func' }

      it 'keeps the object name unchanged' do
        expect(generator.object_name).to eq('test_module::my_func')
      end
    end

    context 'when the given name does not start with the module name' do
      let(:given_name) { 'my_func' }

      it 'prepends the module name to the object name' do
        expect(generator.object_name).to eq('test_module::my_func')
      end
    end
  end

  describe '#friendly_name' do
    it 'returns a human-readable name' do
      expect(generator.friendly_name).to eq('Function')
    end
  end

  describe '#template_files' do
    let(:given_name) { 'test_module::my_func' }

    context 'when spec_only is true' do
      let(:options) { { spec_only: true, type: 'v4' } }

      it 'only returns the spec template file' do
        expect(generator.template_files.keys).to eq([File.join('functions', 'function_spec.erb')])
      end

      it 'maps the spec template to the correct destination path' do
        expected_path = "#{File.join('spec', 'functions', 'my_func')}_spec.rb"
        expect(generator.template_files[File.join('functions', 'function_spec.erb')]).to eq(expected_path)
      end
    end

    context 'when spec_only is false and type is v4' do
      let(:options) { { spec_only: false, type: 'v4' } }

      it 'includes both spec and implementation template files' do
        template_file = File.join('functions', 'v4_function.erb')
        expect(generator.template_files.keys).to contain_exactly(File.join('functions', 'function_spec.erb'), template_file)
      end

      it 'maps the implementation template to a ruby lib path' do
        template_file = File.join('functions', 'v4_function.erb')
        expected_path = "#{File.join('lib', 'puppet', 'functions', module_name, 'my_func')}.rb"
        expect(generator.template_files[template_file]).to eq(expected_path)
      end
    end

    context 'when spec_only is false and type is v3' do
      let(:options) { { spec_only: false, type: 'v3' } }

      it 'maps the implementation template to a puppet functions path' do
        template_file = File.join('functions', 'v3_function.erb')
        expected_path = "#{File.join('functions', 'my_func')}.pp"
        expect(generator.template_files[template_file]).to eq(expected_path)
      end
    end
  end

  describe '#template_data' do
    let(:given_name) { 'test_module::my_func' }

    it 'returns the full object name' do
      expect(generator.template_data[:name]).to eq('test_module::my_func')
    end

    it 'returns the function short name' do
      expect(generator.template_data[:func_name]).to eq('my_func')
    end

    it 'returns the namespace' do
      expect(generator.template_data[:namespace]).to eq('test_module')
    end
  end
end

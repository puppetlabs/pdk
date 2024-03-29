require 'spec_helper'
require 'pdk/generate/defined_type'

describe PDK::Generate::DefinedType do
  subject(:template_data) { generator.template_data }

  let(:generator) { described_class.new(context, given_name, options) }
  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_name) { given_name }

  let(:target_object_path) { generator.target_object_path }

  let(:target_spec_path) { generator.target_spec_path }

  before do
    test_metadata = { 'name' => module_name }
    allow(PDK::Util).to receive(:module_metadata).and_return(test_metadata)
  end

  shared_examples 'it generates the template data' do
    it 'includes the defined type name in the template data' do
      expect(template_data).to eq(name: expected_name)
    end
  end

  shared_examples 'it generates a spec file' do
    it 'writes the spec file into the correct location' do
      expect(generator.template_files).to include('defined_type_spec.erb' => expected_spec_path)
    end
  end

  describe '#template_files' do
    let(:given_name) { module_name }

    context 'when spec_only is true' do
      let(:options) { { spec_only: true } }

      it 'only returns spec files' do
        expect(generator.template_files.keys).to eq(['defined_type_spec.erb'])
      end
    end

    context 'when spec_only is false' do
      let(:options) { { spec_only: false } }

      it 'only returns all files' do
        expect(generator.template_files.keys).to eq(['defined_type_spec.erb', 'defined_type.erb'])
      end
    end
  end

  context 'when the defined type name is the same as the module name' do
    let(:given_name) { module_name }
    let(:expected_object_path) { File.join('manifests', 'init.pp') }
    let(:expected_spec_path) { File.join('spec', 'defines', "#{expected_name}_spec.rb") }

    it_behaves_like 'it generates the template data'
    it_behaves_like 'it generates a spec file'

    it 'writes the defined type to manifests/init.pp' do
      expect(generator.template_files).to include('defined_type.erb' => expected_object_path)
    end
  end

  context 'when the defined type name is in the module namespace' do
    let(:given_name) { "#{module_name}::test_define" }
    let(:expected_object_path) { File.join('manifests', 'test_define.pp') }
    let(:expected_spec_path) { File.join('spec', 'defines', 'test_define_spec.rb') }

    it_behaves_like 'it generates the template data'
    it_behaves_like 'it generates a spec file'

    it 'writes the defined type to manifests/test_define.pp' do
      expect(generator.template_files).to include('defined_type.erb' => expected_object_path)
    end
  end

  context 'when the defined type is deeply nested in the module namespace' do
    let(:given_name) { "#{module_name}::something::else::test_define" }
    let(:expected_object_path) { File.join('manifests', 'something', 'else', 'test_define.pp') }
    let(:expected_spec_path) { File.join('spec', 'defines', 'something', 'else', 'test_define_spec.rb') }

    it_behaves_like 'it generates the template data'
    it_behaves_like 'it generates a spec file'

    it 'writes the defined type to manifests/something/else/test_define.pp' do
      expect(generator.template_files).to include('defined_type.erb' => expected_object_path)
    end
  end

  context 'when the defined type name is outside the module namespace' do
    let(:given_name) { 'test_define' }
    let(:expected_name) { [module_name, given_name].join('::') }
    let(:expected_object_path) { File.join('manifests', 'test_define.pp') }
    let(:expected_spec_path) { File.join('spec', 'defines', 'test_define_spec.rb') }

    it 'prepends the module name to the defined type name' do
      expect(generator.object_name).to eq(expected_name)
    end

    it_behaves_like 'it generates the template data'
    it_behaves_like 'it generates a spec file'

    it 'writes the defined type to manifests/test_define.pp' do
      expect(generator.template_files).to include('defined_type.erb' => expected_object_path)
    end
  end
end

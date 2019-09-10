require 'spec_helper'

shared_examples 'it generates class template data' do
  it 'includes the class name in the template data' do
    expect(templated_class.template_data).to eq(name: expected_class_name)
  end
end

describe PDK::Generate::PuppetClass do
  subject(:templated_class) { described_class.new(module_dir, given_class_name, options) }

  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_class_name) { given_class_name }

  before(:each) do
    test_metadata = { 'name' => module_name }
    allow(PDK::Util).to receive(:module_metadata).and_return(test_metadata)
  end

  context 'when the class name is the same as the module name' do
    let(:given_class_name) { module_name }

    it_behaves_like 'it generates class template data'

    it 'writes the class to init.pp' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'manifests', 'init.pp'))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', "#{expected_class_name}_spec.rb"))
    end
  end

  context 'when the class name is in the module namespace' do
    let(:given_class_name) { "#{module_name}::test_class" }

    it_behaves_like 'it generates class template data'

    it 'writes the class to a file matching the class name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'manifests', 'test_class.pp'))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'test_class_spec.rb'))
    end
  end

  context 'when the class name is deeply nested in the module namespace' do
    let(:given_class_name) { "#{module_name}::something::else::test_class" }

    it 'includes the class name in the template data' do
      expect(templated_class.template_data).to eq(name: expected_class_name)
    end

    it 'writes the class to a file matching the class name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'manifests', 'something', 'else', 'test_class.pp'))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'something', 'else', 'test_class_spec.rb'))
    end
  end

  context 'when the class name is outside the module namespace' do
    let(:given_class_name) { 'test_class' }
    let(:expected_class_name) { "#{module_name}::#{given_class_name}" }

    it 'includes the class name in the template data' do
      expect(templated_class.template_data).to eq(name: expected_class_name)
    end

    it 'prepends the module name to the class name' do
      expect(templated_class.object_name).to eq(expected_class_name)
    end

    it 'uses the class name as file name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'manifests', "#{given_class_name}.pp"))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', "#{given_class_name}_spec.rb"))
    end
  end
end

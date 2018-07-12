require 'spec_helper'

shared_examples 'it generates role template data' do
  it 'includes the role name in the template data' do
    expect(templated_class.template_data).to eq(name: expected_class_name)
  end
end

describe PDK::Generate::Role do
  subject(:templated_class) { described_class.new(module_dir, given_class_name, options) }

  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_class_name) { given_class_name }

  before(:each) do
    test_metadata = instance_double(PDK::Module::Metadata, data: { 'name' => module_name })
    allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(module_dir, 'metadata.json')).and_return(test_metadata)
  end

  context 'when the role name is in the role namespace' do
    let(:given_class_name) { "role::test_role" }

    it_behaves_like 'it generates role template data'

    it 'writes the role to a file matching the role name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'site', 'role', 'manifests', 'test_role.pp'))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'role', 'test_role_spec.rb'))
    end
  end

  context 'when the role name is outside the module namespace' do
    let(:given_class_name) { 'test_role' }
    let(:expected_class_name) { "role::#{given_class_name}" }

    it 'includes the role name in the template data' do
      expect(templated_class.template_data).to eq(name: expected_class_name)
    end

    it 'prepends the module name to the role name' do
      expect(templated_class.object_name).to eq(expected_class_name)
    end

    it 'uses the role name as file name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'site', 'role', 'manifests', "#{given_class_name}.pp"))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'role', "#{given_class_name}_spec.rb"))
    end
  end
end

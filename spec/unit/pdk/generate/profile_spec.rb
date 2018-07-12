require 'spec_helper'

shared_examples 'it generates profile template data' do
  it 'includes the profile name in the template data' do
    expect(templated_class.template_data).to eq(name: expected_class_name)
  end
end

describe PDK::Generate::Profile do
  subject(:templated_class) { described_class.new(module_dir, given_class_name, options) }

  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_class_name) { given_class_name }

  before(:each) do
    test_metadata = instance_double(PDK::Module::Metadata, data: { 'name' => module_name })
    allow(PDK::Module::Metadata).to receive(:from_file).with(File.join(module_dir, 'metadata.json')).and_return(test_metadata)
  end

  context 'when the profile name is in the profile namespace' do
    let(:given_class_name) { 'profile::test_profile' }

    it_behaves_like 'it generates profile template data'

    it 'writes the profile to a file matching the profile name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'site', 'profile', 'manifests', 'test_profile.pp'))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'profile', 'test_profile_spec.rb'))
    end
  end

  context 'when the profile name is outside the module namespace' do
    let(:given_class_name) { 'test_profile' }
    let(:expected_class_name) { "profile::#{given_class_name}" }

    it 'includes the profile name in the template data' do
      expect(templated_class.template_data).to eq(name: expected_class_name)
    end

    it 'prepends the module name to the profile name' do
      expect(templated_class.object_name).to eq(expected_class_name)
    end

    it 'uses the profile name as file name' do
      expect(templated_class.target_object_path).to eq(File.join(module_dir, 'site', 'profile', 'manifests', "#{given_class_name}.pp"))
    end

    it 'writes the spec file into the classes directory' do
      expect(templated_class.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'profile', "#{given_class_name}_spec.rb"))
    end
  end
end

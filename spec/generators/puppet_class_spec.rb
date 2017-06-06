require 'spec_helper'

describe PDK::Generate::PuppetClass do
  subject { described_class.new(module_dir, class_name) }

  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }

  before(:each) do
    allow_any_instance_of(described_class).to receive(:module_name).and_return(module_name)
  end

  context 'when the class name is the same as the module name' do
    let(:class_name) { module_name }

    it 'will write the class to init.pp' do
      expect(subject.target_object_path).to eq(File.join(module_dir, 'manifests', 'init.pp'))
    end

    it 'will write the spec file into the classes directory' do
      expect(subject.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', "#{class_name}_spec.rb"))
    end
  end

  context 'when the class name is in the module namespace' do
    let(:class_name) { "#{module_name}::test_class" }

    it 'will write the class to a file matching the class name' do
      expect(subject.target_object_path).to eq(File.join(module_dir, 'manifests', 'test_class.pp'))
    end

    it 'will write the spec file into the classes directory' do
      expect(subject.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'test_class_spec.rb'))
    end
  end

  context 'when the class name is deeply nested in the module namespace' do
    let(:class_name) { "#{module_name}::something::else::test_class" }

    it 'will write the class to a file matching the class name' do
      expect(subject.target_object_path).to eq(File.join(module_dir, 'manifests', 'something', 'else', 'test_class.pp'))
    end

    it 'will write the spec file into the classes directory' do
      expect(subject.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', 'something', 'else', 'test_class_spec.rb'))
    end
  end

  context 'when the class name is outside the module namespace' do
    let(:class_name) { 'test_class' }

    it 'will prepend the module name to the class name' do
      expect(subject.object_name).to eq("#{module_name}::#{class_name}")
      expect(subject.target_object_path).to eq(File.join(module_dir, 'manifests', "#{class_name}.pp"))
    end

    it 'will write the spec file into the classes directory' do
      expect(subject.target_spec_path).to eq(File.join(module_dir, 'spec', 'classes', "#{class_name}_spec.rb"))
    end
  end
end

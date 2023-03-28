require 'spec_helper'
require 'pdk/generate/puppet_class'

shared_examples 'it generates class template data' do
  it 'includes the class name in the template data' do
    expect(generator.template_data).to eq(name: expected_class_name)
  end
end

describe PDK::Generate::PuppetClass do
  subject(:generator) { described_class.new(context, given_class_name, options) }

  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_name) { 'test_module' }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:expected_class_name) { given_class_name }

  before do
    test_metadata = { 'name' => module_name }
    allow(PDK::Util).to receive(:module_metadata).and_return(test_metadata)
  end

  shared_examples 'it generates an object file' do
    it 'writes the object file into the correct location' do
      expect(generator.template_files).to include('class.erb' => expected_object_path)
    end
  end

  shared_examples 'it generates a spec file' do
    it 'writes the spec file into the correct location' do
      expect(generator.template_files).to include('class_spec.erb' => expected_spec_path)
    end
  end

  describe '#template_files' do
    let(:given_class_name) { module_name }

    context 'when spec_only is true' do
      let(:options) { { spec_only: true } }

      it 'only returns spec files' do
        expect(generator.template_files.keys).to eq(['class_spec.erb'])
      end
    end

    context 'when spec_only is false' do
      let(:options) { { spec_only: false } }

      it 'only returns all files' do
        expect(generator.template_files.keys).to eq(['class_spec.erb', 'class.erb'])
      end
    end
  end

  context 'when the class name is the same as the module name' do
    let(:given_class_name) { module_name }
    let(:expected_spec_path) { File.join('spec', 'classes', "#{expected_class_name}_spec.rb") }
    let(:expected_object_path) { File.join('manifests', 'init.pp') }

    include_examples 'it generates class template data'
    include_examples 'it generates an object file'
    include_examples 'it generates a spec file'
  end

  context 'when the class name is in the module namespace' do
    let(:given_class_name) { "#{module_name}::test_class" }
    let(:expected_spec_path) { File.join('spec', 'classes', 'test_class_spec.rb') }
    let(:expected_object_path) { File.join('manifests', 'test_class.pp') }

    include_examples 'it generates class template data'
    include_examples 'it generates an object file'
    include_examples 'it generates a spec file'
  end

  context 'when the class name is deeply nested in the module namespace' do
    let(:given_class_name) { "#{module_name}::something::else::test_class" }
    let(:expected_spec_path) { File.join('spec', 'classes', 'something', 'else', 'test_class_spec.rb') }
    let(:expected_object_path) { File.join('manifests', 'something', 'else', 'test_class.pp') }

    include_examples 'it generates class template data'
    include_examples 'it generates an object file'
    include_examples 'it generates a spec file'
  end

  context 'when the class name is outside the module namespace' do
    let(:given_class_name) { 'test_class' }
    let(:expected_class_name) { "#{module_name}::#{given_class_name}" }
    let(:expected_spec_path) { File.join('spec', 'classes', "#{given_class_name}_spec.rb") }
    let(:expected_object_path) { File.join('manifests', "#{given_class_name}.pp") }

    include_examples 'it generates class template data'
    include_examples 'it generates an object file'
    include_examples 'it generates a spec file'

    it 'prepends the module name to the class name' do
      expect(generator.object_name).to eq(expected_class_name)
    end
  end
end

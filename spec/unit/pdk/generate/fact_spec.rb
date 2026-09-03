require 'spec_helper'
require 'pdk/generate/fact'

describe PDK::Generate::Fact do
  subject(:generator) { described_class.new(context, given_name, options) }

  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:given_name) { 'my_fact' }

  it 'inherits from PuppetObject' do
    expect(generator).to be_a(PDK::Generate::PuppetObject)
  end

  describe '#friendly_name' do
    it 'returns a human-readable name' do
      expect(generator.friendly_name).to eq('Custom Fact')
    end
  end

  describe '#template_files' do
    context 'when spec_only is true' do
      let(:options) { { spec_only: true } }

      it 'only returns the spec template file' do
        expect(generator.template_files.keys).to eq(['fact_spec.erb'])
      end

      it 'maps the spec template to the correct destination path' do
        expect(generator.template_files['fact_spec.erb']).to eq(File.join('spec', 'unit', 'facter', given_name) + '_spec.rb')
      end
    end

    context 'when spec_only is false' do
      let(:options) { { spec_only: false } }

      it 'returns both the spec and implementation template files' do
        expect(generator.template_files.keys).to contain_exactly('fact_spec.erb', 'fact.erb')
      end

      it 'maps the implementation template to the correct destination path' do
        expect(generator.template_files['fact.erb']).to eq(File.join('lib', 'facter', given_name) + '.rb')
      end
    end
  end

  describe '#template_data' do
    it 'returns the object name' do
      expect(generator.template_data).to eq(name: given_name)
    end
  end
end

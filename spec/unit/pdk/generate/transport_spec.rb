require 'spec_helper'
require 'pdk/generate/transport'

describe PDK::Generate::Transport do
  subject(:generator) { described_class.new(context, given_name, options) }

  let(:context) { PDK::Context::Module.new(module_dir, module_dir) }
  let(:module_dir) { '/tmp/test_module' }
  let(:options) { {} }
  let(:given_name) { 'test_transport' }

  it 'inherits from PuppetObject' do
    expect(generator).to be_a(PDK::Generate::PuppetObject)
  end

  describe '#template_files' do
    let(:given_class_name) { module_name }

    context 'when spec_only is true' do
      let(:options) { { spec_only: true } }

      it 'only returns spec files' do
        expect(generator.template_files.keys).to eq(['transport_spec.erb', 'transport_type_spec.erb'])
      end
    end

    context 'when spec_only is false' do
      let(:options) { { spec_only: false } }

      it 'returns all files' do
        expect(generator.template_files.keys).to eq(['transport_spec.erb', 'transport_type_spec.erb', 'transport.erb', 'transport_device.erb', 'transport_type.erb'])
      end
    end
  end

  # TODO: Write some tests!!
end

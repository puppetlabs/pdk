require 'spec_helper'
require 'pdk/template/renderer/v1'

describe PDK::Template::Renderer::V1 do
  let(:template_root) { '/some/path' }
  let(:template_uri) { PDK::Util::TemplateURI.new(template_root) }
  let(:pdk_context) { PDK::Context::None.new(nil) }

  describe '.compatible?' do
    subject(:compatible) { described_class.compatible?(template_root, pdk_context) }

    context 'when all module template directories exist' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/some/path/moduleroot').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/some/path/moduleroot_init').and_return(true)
      end

      it 'is compatible' do
        expect(compatible).to be true
      end
    end

    context 'when only some of module template directories exist' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/some/path/moduleroot').and_return(true)
        allow(PDK::Util::Filesystem).to receive(:directory?).with('/some/path/moduleroot_init').and_return(false)
      end

      it 'is not compatible' do
        expect(compatible).to be false
      end
    end
  end

  describe '.instance' do
    it 'creates a PDK::Template::Renderer::V1::Renderer object' do
      expect(described_class.instance(template_root, template_uri, pdk_context)).to be_a(PDK::Template::Renderer::V1::Renderer)
    end
  end
end

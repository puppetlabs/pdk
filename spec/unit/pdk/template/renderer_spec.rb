require 'spec_helper'
require 'pdk/template/renderer'

describe PDK::Template::Renderer do
  let(:template_path) { '/some/path' }
  let(:template_uri) { PDK::Util::TemplateURI.new(template_path) }
  let(:pdk_context) { PDK::Context::None.new(nil) }

  describe '.instance' do
    subject(:instance) { described_class.instance(template_uri, template_path, pdk_context) }

    context 'given an original template directory' do
      before do
        allow(PDK::Template::Renderer::V1).to receive(:compatible?).and_return(true)
      end

      it 'creates a version 1 renderer' do
        expect(instance).to be_a(PDK::Template::Renderer::V1::Renderer)
      end
    end

    context 'given a template that has no appropriate renderer' do
      before do
        allow(PDK::Template::Renderer::V1).to receive(:compatible?).and_return(false)
      end

      it 'creates a Local Fetcher object' do
        expect(instance).to be_nil
      end
    end
  end

  describe PDK::Template::Renderer::AbstractRenderer do
    subject(:renderer) { described_class.new(template_path, template_uri, pdk_context) }

    it 'responds to template_root' do
      expect(renderer.template_root).to eq(template_path)
    end

    it 'responds to template_uri' do
      expect(renderer.template_uri).to eq(template_uri)
    end

    it 'responds to context' do
      expect(renderer.context).to eq(pdk_context)
    end

    it 'responds to has_single_item?' do
      expect(renderer.has_single_item?(nil)).to be false
    end

    it 'responds to render' do
      expect(renderer.render(nil, nil, nil)).to be_nil
    end

    it 'responds to render_single_item' do
      expect(renderer.render_single_item(nil, nil)).to be_nil
    end
  end
end

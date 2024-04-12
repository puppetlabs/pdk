require 'spec_helper'
require 'pdk/template'

describe PDK::Template do
  let(:pdk_context) { PDK::Context::None.new(nil) }
  let(:template_uri) { PDK::Util::TemplateURI.new(PDK::Util::TemplateURI::PDK_TEMPLATE_URL) }

  describe '.with' do
    context 'when not passed a block' do
      it 'raises an ArgumentError' do
        expect do
          described_class.with(template_uri, pdk_context)
        end.to raise_error(ArgumentError, /must be passed a block/i)
      end
    end

    context 'when not initialized with a PDK::Util::TemplateURI' do
      let(:template_uri) { 'string uri' }

      it 'raises an ArgumentError' do
        expect do
          described_class.with(template_uri, pdk_context) {}
        end.to raise_error(ArgumentError, /must be passed a PDK::Util::TemplateURI/i)
      end
    end

    context 'when initialized correctly' do
      let(:fetcher) { described_class::Fetcher::AbstractFetcher.new(template_uri, {}) }
      let(:template_dir) do
        described_class::TemplateDir.new(
          template_uri,
          nil,
          pdk_context,
          instance_double(described_class::Renderer::AbstractRenderer)
        )
      end

      before do
        expect(described_class::Fetcher).to receive(:with).with(template_uri).and_yield(fetcher)
        allow(described_class::TemplateDir).to receive(:instance).with(template_uri, anything, pdk_context).and_return(template_dir)
      end

      it 'fetches remote templates' do
        described_class.with(template_uri, pdk_context) {}
      end

      it 'yields a PDK::Template::TemplateDir' do
        expect { |b| described_class.with(template_uri, pdk_context, &b) }.to yield_with_args(template_dir)
      end
    end
  end
end

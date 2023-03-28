require 'spec_helper'
require 'pdk/template'

describe PDK::Template do
  let(:pdk_context) { PDK::Context::None.new(nil) }
  let(:template_uri) { PDK::Util::TemplateURI.new(PDK::Util::TemplateURI::PDK_TEMPLATE_URL) }

  describe '.with' do
    context 'when not passed a block' do
      it 'raises an ArgumentError' do
        expect {
          described_class.with(template_uri, pdk_context)
        }.to raise_error(ArgumentError, %r{must be passed a block}i)
      end
    end

    context 'when not initialized with a PDK::Util::TemplateURI' do
      let(:template_uri) { 'string uri' }

      it 'raises an ArgumentError' do
        expect {
          described_class.with(template_uri, pdk_context) {}
        }.to raise_error(ArgumentError, %r{must be passed a PDK::Util::TemplateURI}i)
      end
    end

    context 'when initialized correctly' do
      let(:fetcher) { PDK::Template::Fetcher::AbstractFetcher.new(template_uri, {}) }
      let(:template_dir) do
        PDK::Template::TemplateDir.new(
          template_uri,
          nil,
          pdk_context,
          instance_double(PDK::Template::Renderer::AbstractRenderer),
        )
      end

      before do
        expect(PDK::Template::Fetcher).to receive(:with).with(template_uri).and_yield(fetcher)
        allow(PDK::Template::TemplateDir).to receive(:instance).with(template_uri, anything, pdk_context).and_return(template_dir)
      end

      it 'fetches remote templates' do
        described_class.with(template_uri, pdk_context) {}
      end

      it 'yields a PDK::Template::TemplateDir' do
        expect { |b| described_class.with(template_uri, pdk_context, &b) }.to yield_with_args(template_dir)
      end

      it 'sends analytics event' do
        expect(PDK.analytics).to receive(:event).with('TemplateDir', 'initialize', anything)
        described_class.with(template_uri, pdk_context) {}
      end
    end
  end
end

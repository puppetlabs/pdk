require 'spec_helper'
require 'pdk/template/template_dir'

describe PDK::Template::TemplateDir do
  subject(:template_dir) { described_class.new(template_uri, template_path, pdk_context, renderer) }

  let(:template_uri) { PDK::Util::TemplateURI.new(PDK::Util::TemplateURI::PDK_TEMPLATE_URL) }
  let(:template_path) { '/some/path' }
  let(:pdk_context) { PDK::Context::None.new(nil) }
  let(:renderer) { instance_double('PDK::Template::Renderer::AbstractRenderer') }

  describe '#instance' do
    it 'creates a TemplateDir object' do
      expect(described_class.instance(template_uri, template_path, pdk_context, renderer)).to be_a(PDK::Template::TemplateDir) # rubocop:disable RSpec/DescribedClass No, this is correct
    end
  end

  context 'when not passed a renderer' do
    subject(:template_dir) { described_class.new(template_uri, template_path, pdk_context) }

    it 'tries to create a renderer' do
      expect(PDK::Template::Renderer).to receive(:instance).with(template_uri, template_path, pdk_context).and_return(renderer)

      template_dir
    end

    context 'when a renderer could not be found' do
      before(:each) do
        expect(PDK::Template::Renderer).to receive(:instance).with(template_uri, template_path, pdk_context).and_return(nil)
      end

      it 'raises a RuntimeError' do
        expect { template_dir }.to raise_error(RuntimeError, %r{Could not find a compatible})
      end
    end
  end

  it 'has a uri method' do
    expect(template_dir.uri).to be(template_uri)
  end

  it 'has a path method' do
    expect(template_dir.path).to be(template_path)
  end

  it 'has a metadata method' do
    expect(template_dir.metadata).to eq({})
  end

  it 'delegates a render method' do
    expect(renderer).to receive(:render)
    template_dir.render(nil, nil, nil)
  end

  it 'delegates a render_single_item method' do
    expect(renderer).to receive(:render_single_item)
    template_dir.render_single_item(nil, nil)
  end

  it 'delegates a has_single_item? method' do
    expect(renderer).to receive(:has_single_item?)
    template_dir.has_single_item?(nil)
  end
end

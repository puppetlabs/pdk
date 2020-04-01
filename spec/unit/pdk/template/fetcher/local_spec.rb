require 'spec_helper'
require 'pdk/template/fetcher/local'

describe PDK::Template::Fetcher::Local do
  subject(:fetcher) { described_class.new(template_uri, pdk_context) }

  let(:template_path) { '/some/path' }
  let(:template_uri) { PDK::Util::TemplateURI.new(template_path) }
  let(:pdk_context) { PDK::Context::None.new(nil) }

  describe '.fetchable?' do
    it 'is always fetchable' do
      expect(described_class.fetchable?(nil, nil)).to be true
    end
  end

  describe '.fetch!' do
    it 'is not temporary' do
      fetcher.fetch!
      expect(fetcher.temporary).to be false
    end

    it 'uses the path from the uri' do
      fetcher.fetch!
      expect(fetcher.path).to eq(template_path)
    end

    it 'sets template-url in the metadata' do
      fetcher.fetch!
      expect(fetcher.metadata).to include('template-url' => template_path)
    end
  end
end

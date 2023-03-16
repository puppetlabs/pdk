require 'spec_helper'
require 'pdk/template/fetcher'

describe PDK::Template::Fetcher do
  let(:template_uri) { PDK::Util::TemplateURI.new('/some/path') }
  let(:fetcher_options) { {} }

  describe '.instance' do
    subject(:instance) { described_class.instance(template_uri, fetcher_options) }

    context 'given a git based uri' do
      let(:template_uri) { PDK::Util::TemplateURI.new('https://github.com/puppetlabs/pdk-templates') }

      it 'creates a Git Fetcher object' do
        expect(instance).to be_a(PDK::Template::Fetcher::Git)
      end
    end

    context 'given any other uri' do
      let(:template_uri) { PDK::Util::TemplateURI.new('/some/path') }

      before(:each) do
        allow(PDK::Template::Fetcher::Git).to receive(:fetchable?).and_return(false)
      end

      it 'creates a Local Fetcher object' do
        expect(instance).to be_a(PDK::Template::Fetcher::Local)
      end
    end
  end

  describe '.with' do
    let(:fetcher) { PDK::Template::Fetcher::AbstractFetcher.new(template_uri, fetcher_options) }

    before(:each) do
      allow(described_class).to receive(:instance).with(template_uri, fetcher_options).and_return(fetcher)
    end

    context 'when not passed a block' do
      it 'raises an ArgumentError' do
        expect {
          described_class.with(template_uri, fetcher_options)
        }.to raise_error(ArgumentError, %r{must be passed a block}i)
      end
    end

    it 'yields a PDK::Template::Fetcher::AbstractFetcher object' do
      expect { |b| described_class.with(template_uri, fetcher_options, &b) }.to yield_with_args(fetcher)
    end

    it 'fetches the template before it yields the fetcher' do
      described_class.with(template_uri, fetcher_options) do |fetcher|
        expect(fetcher.fetched).to be true
      end
    end

    context 'when the fetch is temporary' do
      before(:each) do
        allow(fetcher).to receive(:temporary).and_return(true)
      end

      it 'deletes the temporary path' do
        expect(PDK::Util::Filesystem).to receive(:rm_rf)
        described_class.with(template_uri, fetcher_options) {}
      end
    end

    context 'when the fetch is not temporary' do
      before(:each) do
        allow(fetcher).to receive(:temporary).and_return(false)
      end

      it 'does not delete the temporary path' do
        expect(PDK::Util::Filesystem).not_to receive(:rm_rf)
        described_class.with(template_uri, fetcher_options) {}
      end
    end
  end

  describe PDK::Template::Fetcher::AbstractFetcher do
    subject(:fetcher) { described_class.new(template_uri, fetcher_options) }

    it 'responds to uri' do
      expect(fetcher.uri).to eq(template_uri)
    end

    it 'responds to path' do
      expect(fetcher.path).to be_nil
    end

    it 'responds to temporary' do
      expect(fetcher.temporary).to be false
    end

    it 'responds to fetched' do
      expect(fetcher.fetched).to be false
    end

    it 'responds to metadata' do
      expect(fetcher.metadata).to include(
        'pdk-version' => anything,
        'template-url' => nil,
        'template-ref' => nil,
      )
    end

    it 'responds to fetch!' do
      expect(fetcher.fetched).to be false
      fetcher.fetch!
      expect(fetcher.fetched).to be true
    end
  end
end

require 'spec_helper'
require 'securerandom'
require 'pdk/analytics'

describe PDK::Analytics do
  let(:default_config) { {} }
  let(:logger) { instance_double(Logger, debug: true) }
  let(:uuid) { SecureRandom.uuid }

  before(:each) do
    # We use a hard override to disable analytics for tests, but that obviously
    # interferes with these tests...
    allow(PDK::Util::Env).to receive(:[]).with('PDK_DISABLE_ANALYTICS').and_return(nil)
  end

  describe '.build_client' do
    subject { described_class.build_client(options) }

    let(:options) do
      {
        logger: logger,
        client: :google_analytics,
        disabled: disabled,
        user_id: uuid,
        app_name: 'pdk',
        app_version: PDK::VERSION,
        app_id: '1',
      }
    end

    context 'when analytics is disabled' do
      let(:disabled) { true }

      it 'returns an instance of the Noop client' do
        is_expected.to be_an_instance_of(described_class::Client::Noop)
      end
    end

    context 'when analytics are enabled' do
      let(:disabled) { false }

      it 'returns an instance of the GoogleAnalytics client' do
        is_expected.to be_an_instance_of(described_class::Client::GoogleAnalytics)
      end

      context 'when the client instantiation fails' do
        before(:each) do
          allow(described_class::Client::GoogleAnalytics).to receive(:new).and_raise(StandardError)
        end

        it 'returns an instance of the Noop client' do
          is_expected.to be_an_instance_of(described_class::Client::Noop)
        end
      end
    end
  end
end

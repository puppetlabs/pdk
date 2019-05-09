require 'spec_helper'
require 'securerandom'

describe PDK::Analytics do
  let(:default_config) { {} }
  let(:logger) { instance_double(Logger, debug: true) }
  let(:uuid) { SecureRandom.uuid }

  before(:each) do
    # We use a hard override to disable analytics for tests, but that obviously
    # interferes with these tests...
    ENV.delete('PDK_DISABLE_ANALYTICS')
  end

  describe '.build_client' do
    subject { described_class.build_client(logger: logger, uuid: uuid, disabled: disabled) }

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

require 'spec_helper'

describe PDK::Analytics do
  let(:default_config) { {} }
  let(:logger) { instance_double(Logger, debug: true) }

  before(:each) do
    # We use a hard override to disable analytics for tests, but that obviously
    # interferes with these tests...
    ENV.delete('PDK_DISABLE_ANALYTICS')

    # Ensure these tests will never read or write a local config
    allow(described_class).to receive(:load_config).and_return(default_config)
    allow(described_class).to receive(:write_config)
  end

  describe '.build_client' do
    subject { described_class.build_client(logger: logger) }

    context 'when analytics is disabled' do
      before(:each) do
        default_config.replace('disabled' => true)
      end

      it 'returns an instance of the Noop client' do
        is_expected.to be_an_instance_of(described_class::Client::Noop)
      end
    end

    context 'when analytics are enabled' do
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

  # TODO: refactor these tests
  it 'uses the uuid in the config if it exists' do
    uuid = SecureRandom.uuid
    default_config.replace('user-id' => uuid)

    expect(described_class.build_client(logger: logger).user_id).to eq(uuid)
  end

  it "assigns the user a uuid if one doesn't exist" do
    uuid = SecureRandom.uuid
    allow(SecureRandom).to receive(:uuid).and_return(uuid)

    expect(described_class).to receive(:write_config).with(kind_of(String), include('user-id' => uuid))

    expect(described_class.build_client(logger: logger).user_id).to eq(uuid)
  end
end

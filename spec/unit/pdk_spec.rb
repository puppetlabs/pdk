require 'spec_helper'

describe PDK do
  describe '.logger', use_stubbed_logger: false do
    subject { described_class.logger }

    it { is_expected.to be_an_instance_of(PDK::Logger) }
  end

  describe '.config' do
    subject(:config) { described_class.config }

    it { is_expected.to be_an_instance_of(PDK::Config) }

    it 'is memoised' do
      expect(logger).to eq(described_class.logger)
    end
  end
end

require 'spec_helper'
require 'pdk'

describe PDK do
  describe '.logger', use_stubbed_logger: false do
    subject { described_class.logger }

    it { is_expected.to be_an_instance_of(PDK::Logger) }
  end

  describe '.config' do
    subject(:config) { described_class.config }

    it { is_expected.to be_an_instance_of(PDK::Config) }

    it 'is memoised' do
      object1 = PDK.config # rubocop:disable RSpec/DescribedClass have to use the explicit form due to rspec caching
      object2 = PDK.config # rubocop:disable RSpec/DescribedClass have to use the explicit form due to rspec caching
      expect(object2).to be(object1)
    end
  end
end

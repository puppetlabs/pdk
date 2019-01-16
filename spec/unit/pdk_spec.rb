require 'spec_helper'

describe PDK do
  describe '.logger', use_stubbed_logger: false do
    subject { described_class.logger }

    it { is_expected.to be_an_instance_of(PDK::Logger) }
  end

  describe 'slack test' do
    it 'should fail' do
      expect(true).to be_false
    end
  end
end

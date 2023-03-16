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

  describe '.context' do
    subject(:context) { described_class.context }

    it { is_expected.to be_a(PDK::Context::AbstractContext) }

    it 'is memoised' do
      object1 = PDK.context # rubocop:disable RSpec/DescribedClass have to use the explicit form due to rspec caching
      object2 = PDK.context # rubocop:disable RSpec/DescribedClass have to use the explicit form due to rspec caching
      expect(object2).to be(object1)
    end
  end

  describe '.feature_flag?' do
    around(:each) do |example|
      old_flags = ENV.fetch('PDK_FEATURE_FLAGS', nil)
      ENV['PDK_FEATURE_FLAGS'] = flag_env_var
      example.run
      ENV['PDK_FEATURE_FLAGS'] = old_flags
    end

    before(:each) do
      allow(described_class).to receive(:available_feature_flags).and_return(%w[setflag unsetflag])
      # Reset memoized variables
      described_class.instance_variable_set(:@requested_feature_flags, nil)
    end

    shared_examples 'an unset flag' do
      it 'does not have the flag set' do
        expect(described_class.feature_flag?('setflag')).to eq(false)
      end
    end

    shared_examples 'a set flag' do
      it 'has the flag set' do
        expect(described_class.feature_flag?('setflag')).to eq(true)
      end
    end

    shared_examples 'an unavailable flag' do
      it 'does not have the flag set' do
        # Even if the flag is set, if it's not available then it is always false
        expect(described_class.feature_flag?('unavailable')).to eq(false)
      end
    end

    context 'with missing environment variable' do
      let(:flag_env_var) { nil }

      include_examples 'an unset flag'
    end

    context 'with empty environment variable' do
      let(:flag_env_var) { '' }

      include_examples 'an unset flag'
    end

    context 'with mismatched flagname' do
      let(:flag_env_var) { 'otherflag' }

      include_examples 'an unset flag'
    end

    context 'in a list of flags with the wrong delimeter' do
      let(:flag_env_var) { 'abc:  setflag  : 123' }

      include_examples 'an unset flag'
    end

    context 'as the only flag' do
      let(:flag_env_var) { 'setflag' }

      include_examples 'a set flag'
    end

    context 'as an unavailable flage' do
      let(:flag_env_var) { 'unavailable' }

      include_examples 'an unavailable flag'
    end

    context 'in a list of flags' do
      let(:flag_env_var) { 'abc,  setflag  , 123' }

      include_examples 'a set flag'
    end
  end
end

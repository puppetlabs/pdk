require 'spec_helper'
require 'pdk/validate/ruby/ruby_validator_group'

describe PDK::Validate::Ruby::RubyValidatorGroup do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('ruby') }
  end

  describe '.validators' do
    subject { described_class.new.validators }

    it { is_expected.not_to be_empty }
  end
end

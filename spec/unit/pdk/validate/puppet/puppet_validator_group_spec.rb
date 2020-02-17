require 'spec_helper'
require 'pdk/validate/puppet/puppet_validator_group'

describe PDK::Validate::Puppet::PuppetValidatorGroup do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('puppet') }
  end

  describe '.validators' do
    subject { described_class.new.validators }

    it { is_expected.not_to be_empty }
  end
end

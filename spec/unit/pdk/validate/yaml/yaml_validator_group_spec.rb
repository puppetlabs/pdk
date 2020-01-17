require 'spec_helper'
require 'pdk/validate/yaml/yaml_validator_group'

describe PDK::Validate::YAML::YAMLValidatorGroup do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('yaml') }
  end

  describe '.validators' do
    subject { described_class.new.validators }

    it { is_expected.not_to be_empty }
  end
end

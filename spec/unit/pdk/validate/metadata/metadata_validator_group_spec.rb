require 'spec_helper'
require 'pdk/validate/metadata/metadata_validator_group'

describe PDK::Validate::Metadata::MetadataValidatorGroup do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('metadata') }
  end

  describe '.validators' do
    subject { described_class.new.validators }

    it { is_expected.not_to be_empty }
  end
end

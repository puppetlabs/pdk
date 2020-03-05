require 'spec_helper'
require 'pdk/validate/control_repo/control_repo_validator_group'

describe PDK::Validate::ControlRepo::ControlRepoValidatorGroup do
  subject(:validator) { described_class.new(validator_context, validator_options) }

  let(:validator_context) { nil }
  let(:validator_options) { {} }

  describe '.name' do
    subject { validator.name }

    it { is_expected.to eq('control-repo') }
  end

  it_behaves_like 'only valid in specified PDK contexts', PDK::Context::ControlRepo

  describe '.validators' do
    subject { validator.validators }

    it { is_expected.not_to be_empty }
  end
end

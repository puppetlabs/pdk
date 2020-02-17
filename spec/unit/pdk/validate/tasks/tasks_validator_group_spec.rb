require 'spec_helper'
require 'pdk/validate/tasks/tasks_validator_group'

describe PDK::Validate::Tasks::TasksValidatorGroup do
  describe '.name' do
    subject { described_class.new.name }

    it { is_expected.to eq('tasks') }
  end

  describe '.validators' do
    subject { described_class.new.validators }

    it { is_expected.not_to be_empty }
  end
end

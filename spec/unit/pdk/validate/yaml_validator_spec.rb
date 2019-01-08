require 'spec_helper'

describe PDK::Validate::YAMLValidator do
  let(:yaml_validators) do
    [
      PDK::Validate::YAML::Syntax,
    ]
  end

  describe '.name' do
    subject { described_class.name }

    it { is_expected.to eq('yaml') }
  end

  describe '.validators' do
    subject { described_class.validators }

    it { is_expected.to eq(yaml_validators) }
  end

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, {}) }

    let(:report) { PDK::Report.new }

    before(:each) do
      yaml_validators.each do |validator|
        allow(validator).to receive(:invoke).with(report, anything).and_return(validator_return)
      end
    end

    context 'when the validators succeed' do
      let(:validator_return) { 0 }

      it 'returns 0' do
        expect(return_value).to eq(0)
      end
    end

    context 'when the validators fail' do
      let(:validator_return) { 1 }

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end
  end
end

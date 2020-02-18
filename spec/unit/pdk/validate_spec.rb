require 'spec_helper'
require 'pdk/validate'

describe PDK::Validate do
  before(:each) do
    # Remove any memoized variables
    described_class.instance_variable_set(:@validator_hash, nil)
  end

  describe '#validators' do
    it 'is not empty' do
      expect(described_class.validators).not_to be_empty
    end

    it 'all validator instances inherit from PDK::Validate::Validator' do
      expect(described_class.validators.map(&:new)).to all(be_a(PDK::Validate::Validator))
    end
  end

  describe '#validator_names' do
    it 'is not empty' do
      expect(described_class.validator_names).not_to be_empty
    end

    it 'all names are strings' do
      expect(described_class.validator_names).to all(be_a(String))
    end

    it 'all names can be found within the validator_hash' do
      described_class.validator_names.each do |name|
        expect(described_class.validator_hash[name]).not_to be nil
      end
    end
  end

  describe '#validator_hash' do
    it 'is not empty' do
      expect(described_class.validator_hash).not_to be_empty
    end

    it 'all entries have a String key and a Class item' do
      described_class.validator_hash.each do |key, item|
        expect(key).to be_a(String)
        expect(item).to be_a(Class)
      end
    end
  end

  describe '#invoke_validators_by_name' do
    subject(:invokation_result) { described_class.invoke_validators_by_name(pdk_context, validators_to_run, parallel, validation_options) }

    let(:pdk_context) { PDK::Context::None.new(nil) }
    let(:parallel) { false }
    let(:validation_options) { {} }
    let(:mock_hash) do
      {
        'mocksuccess' => MockSuccessValidator,
        'mockfailed'  => MockFailedValidator,
      }
    end

    before(:each) do
      allow(described_class).to receive(:validator_hash).and_return(mock_hash)
    end

    context 'with run in parallel' do
      let(:validators_to_run) { %w[mocksuccess] }
      let(:parallel) { true }

      it 'creates an ExecGroup with parallel set to true' do
        expect(PDK::CLI::ExecGroup).to receive(:create).with(anything, include(parallel: true), validation_options).and_call_original

        exit_code, = invokation_result
        expect(exit_code).to eq(0)
      end
    end

    context 'with run in serial' do
      let(:validators_to_run) { %w[mocksuccess] }
      let(:parallel) { false }

      it 'creates an ExecGroup with parallel set to true' do
        expect(PDK::CLI::ExecGroup).to receive(:create).with(anything, include(parallel: false), validation_options).and_call_original

        exit_code, = invokation_result
        expect(exit_code).to eq(0)
      end
    end

    context 'with only successful validations' do
      let(:validators_to_run) { %w[mocksuccess] }

      it_behaves_like 'a successful result', 1
    end

    context 'with only unknown validations' do
      let(:validators_to_run) { %w[unknown whodis] }

      it_behaves_like 'a successful result', 0
    end

    context 'with only failed validations' do
      let(:validators_to_run) { %w[mockfailed] }

      it_behaves_like 'a failed result', 0, 1
    end

    context 'with failed, uknown and successful validations' do
      let(:validators_to_run) { %w[mocksuccess unknown whodis mockfailed] }

      it_behaves_like 'a failed result', 1, 1
    end
  end
end

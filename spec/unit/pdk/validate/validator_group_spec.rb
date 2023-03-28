require 'spec_helper'
require 'pdk/validate/validator_group'

describe PDK::Validate::ValidatorGroup do
  let(:validator_group) { described_class.new(validator_context, validator_options) }
  let(:validator_context) { nil }
  let(:validator_options) { {} }

  describe '.spinner_text' do
    it 'returns a String' do
      expect(validator_group.spinner_text).to be_a(String)
    end
  end

  describe '.spinner' do
    context 'when spinners are enabled' do
      before do
        allow(validator_group).to receive(:spinners_enabled?).and_return(true)
        allow(validator_group).to receive(:validators).and_return([MockSuccessValidator])
      end

      it 'returns a TTY Multi Spinner with spinner text' do
        obj = validator_group.spinner

        require 'pdk/cli/util/spinner'
        expect(obj).to be_a(TTY::Spinner::Multi)
        expect(obj.first.message).to include(validator_group.spinner_text)
      end

      it 'registers child validator spinners' do
        obj = validator_group.spinner

        # This is a little convulted. The TTY Multi Spinner is Enumerable, so the first item
        # is the parent spinner, and subsequent items and registered child spinners
        expect(obj.entries[1]).to eq(validator_group.validator_instances.first.spinner)
      end
    end

    context 'when spinners are disabled' do
      before do
        allow(validator_group).to receive(:spinners_enabled?).and_return(false)
      end

      it 'returns nil' do
        expect(validator_group.spinner).to be_nil
      end
    end
  end

  describe '.prepare_invoke!' do
    before do
      allow(validator_group).to receive(:validators).and_return([MockSuccessValidator])
    end

    it 'calls prepare_invoke! for each validator in the group' do
      expect(validator_group.validator_instances).to all(receive(:prepare_invoke!).and_call_original)
      validator_group.prepare_invoke!
    end
  end

  it 'has a validators of an empty Array' do
    expect(validator_group.validators).to be_a(Array)
    expect(validator_group.validators).to be_empty
  end

  describe '.invoke' do
    let(:report) { PDK::Report.new }

    before do
      allow(validator_group).to receive(:validators).and_return([MockSuccessValidator])
    end

    it 'calls prepare_invoke!' do
      expect(validator_group).to receive(:prepare_invoke!).and_call_original
      validator_group.invoke(report)
    end

    it 'calls start_spinner' do
      expect(validator_group).to receive(:start_spinner).and_call_original
      validator_group.invoke(report)
    end

    it 'calls invoke of each validator in the group' do
      expect(validator_group.validator_instances).to all(receive(:invoke).with(report).and_call_original)
      validator_group.invoke(report)
    end

    context 'for only succesful validators' do
      it 'returns zero' do
        expect(validator_group.invoke(report)).to eq(0)
      end

      it 'calls stop_spinner with success' do
        expect(validator_group).to receive(:stop_spinner).with(true).and_call_original
        validator_group.invoke(report)
      end
    end

    context 'for both succesful and failed validators' do
      before do
        allow(validator_group).to receive(:validators).and_return([MockSuccessValidator, MockFailedValidator, MockAnotherFailedValidator])
      end

      it 'returns the first failure' do
        expect(validator_group.invoke(report)).to eq(1)
      end

      it 'does not call invoke once a validator has failed' do
        expect(validator_group.validator_instances[0]).to receive(:invoke).and_call_original
        # The second validator fails
        expect(validator_group.validator_instances[1]).to receive(:invoke).and_call_original
        # The third validator also fails but should never be called
        expect(validator_group.validator_instances[2]).not_to receive(:invoke)

        validator_group.invoke(report)
      end

      it 'calls stop_spinner with failure' do
        expect(validator_group).to receive(:stop_spinner).with(false).and_call_original
        validator_group.invoke(report)
      end
    end
  end

  describe '.validator_instances' do
    before do
      allow(validator_group).to receive(:validators).and_return(
        [
          MockSuccessValidator,
          PDK::Validate::Validator,
          MockNoContextValidator,
        ],
      )
    end

    it 'returns instances of the classes in validators' do
      validator_group.validator_instances.each_with_index do |item, index|
        expect(item).to be_a(validator_group.validators[index])
      end
    end

    it 'passes through the context' do
      validator_group.validator_instances.each_with_index do |item, _|
        expect(item.context).to be(validator_group.context)
      end
    end

    it 'returns the same object in mulitple calls' do
      # Get the object_ids for the first call
      object_ids = validator_group.validator_instances.map(&:object_id)
      # Compare the object_ids on the second call
      expect(validator_group.validator_instances.map(&:object_id)).to eq(object_ids)
    end

    it 'only returns validators which are allowed in the PDK context' do
      validator_group.validator_instances.each do |item|
        expect(item).not_to be_a(MockNoContextValidator)
      end
    end
  end
end

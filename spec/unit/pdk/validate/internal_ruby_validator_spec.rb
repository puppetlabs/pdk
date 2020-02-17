require 'spec_helper'
require 'pdk/validate/internal_ruby_validator'

describe PDK::Validate::InternalRubyValidator do
  let(:validator) { described_class.new(validator_context, validator_options) }
  let(:validator_context) { nil }
  let(:validator_options) { {} }
  let(:targets) { [] }
  let(:skipped_targets) { [] }
  let(:invalid_targets) { [] }
  let(:parsed_targets) { [targets, skipped_targets, invalid_targets] }
  let(:report) { PDK::Report.new }

  before(:each) do
    allow(validator).to receive(:name).and_return('mock_name')
    allow(validator).to receive(:parse_targets).and_return(parsed_targets)
  end

  describe '.prepare_invoke!' do
    it 'calls parse_targets only once' do
      expect(validator).to receive(:parse_targets).once.and_return(parsed_targets)

      validator.prepare_invoke!
      validator.prepare_invoke!
      validator.prepare_invoke!
    end

    it 'calls spinner only once' do
      expect(validator).to receive(:spinner).once.and_return(nil)

      validator.prepare_invoke!
      validator.prepare_invoke!
      validator.prepare_invoke!
    end
  end

  describe '.invoke' do
    subject(:invoke) { validator.invoke(report) }

    let(:skipped_targets) { ['skipped'] }
    let(:invalid_targets) { ['invalid'] }

    before(:each) do
      # Order is important! Keep the default response at the top
      allow(validator).to receive(:validate_target).with(report, anything).and_return(nil)
      allow(validator).to receive(:validate_target).with(report, 'success').and_return(0)
      allow(validator).to receive(:validate_target).with(report, 'fail1').and_return(1)
      allow(validator).to receive(:validate_target).with(report, 'fail2').and_return(2)
    end

    context 'when no targets to validate' do
      it 'calls prepare_invoke!' do
        expect(validator).to receive(:prepare_invoke!).and_call_original
        invoke
      end

      it 'calls process_skipped!' do
        expect(validator).to receive(:process_skipped).with(report, skipped_targets).and_call_original
        invoke
      end

      it 'calls process_invalid!' do
        expect(validator).to receive(:process_invalid).with(report, invalid_targets).and_call_original
        invoke
      end

      it 'does not call any validation methods' do
        expect(validator).not_to receive(:before_validation)
        expect(validator).not_to receive(:start_spinner)
        expect(validator).not_to receive(:stop_spinner)
        expect(validator).not_to receive(:validate_target)

        invoke
      end
    end

    context 'with only successful validations' do
      let(:targets) { ['success'] }

      it 'calls before_validation' do
        expect(validator).to receive(:before_validation).and_call_original
        invoke
      end

      it 'calls start_spinner' do
        expect(validator).to receive(:start_spinner).and_call_original
        invoke
      end

      it 'calls stop_spinner with success' do
        expect(validator).to receive(:stop_spinner).with(true).and_call_original
        invoke
      end

      it 'returns zero' do
        expect(invoke).to eq(0)
      end
    end

    context 'with only missing validations' do
      let(:targets) { ['missing'] }

      it 'calls before_validation' do
        expect(validator).to receive(:before_validation).and_call_original
        invoke
      end

      it 'calls start_spinner' do
        expect(validator).to receive(:start_spinner).and_call_original
        invoke
      end

      it 'calls stop_spinner with failure' do
        expect(validator).to receive(:stop_spinner).with(false).and_call_original
        invoke
      end

      it 'returns exit code 1' do
        expect(invoke).to eq(1)
      end

      it 'adds a failed report event' do
        expect(report).to have_number_of_events(:failure, 0)
        invoke
        expect(report).to have_number_of_events(:failure, 1)
      end
    end

    context 'with successful, failed and missing validations' do
      let(:targets) { %w[success fail2 fail1 missing] }

      it 'calls before_validation' do
        expect(validator).to receive(:before_validation).and_call_original
        invoke
      end

      it 'returns highest exit code' do
        expect(invoke).to eq(2)
      end

      it 'adds a failed report event' do
        expect(report).to have_number_of_events(:failure, 0)
        invoke
        expect(report).to have_number_of_events(:failure, 1)
      end

      it 'calls validate_target for all targets' do
        targets.each do |target|
          expect(validator).to receive(:validate_target).with(report, target)
        end

        invoke
      end

      it 'calls stop_spinner with failure' do
        expect(validator).to receive(:stop_spinner).with(false).and_call_original
        invoke
      end
    end
  end

  describe '.validate_target' do
    it 'returns nil' do
      expect(validator.validate_target(report, 'targetfile')).to be_nil
    end
  end

  describe '.before_validation' do
    it 'returns nil' do
      expect(validator.before_validation).to be_nil
    end
  end
end

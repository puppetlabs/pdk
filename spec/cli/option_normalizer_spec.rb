require 'spec_helper'
require 'pdk/cli/util/option_normalizer'

describe PDK::CLI::Util::OptionNormalizer do
  context 'when normalizing lists' do
    it 'normalizes and return an array of strings when the list is comma separated' do
      expect(described_class.comma_separated_list_to_array('a,b,c')).to eq(%w[a b c])
    end

    it 'raises an error when the list is invalid' do
      expect { described_class.comma_separated_list_to_array('a,b c,d') }.to raise_error('Error: expected comma separated list')
    end
  end

  context 'when parsing report formats and targets' do
    context 'when a single format is specified' do
      it 'returns a single Report with the default target when target is not specified' do
        reports = described_class.report_formats(['text'])
        expect(reports.length).to eq(1)
        expect(reports[0].instance_variable_get(:@path)).to eq('stdout')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
      end

      it 'returns a single Report with the specified target when provided' do
        reports = described_class.report_formats(['text:foo.txt'])
        expect(reports.length).to eq(1)
        expect(reports[0].instance_variable_get(:@path)).to eq('foo.txt')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
      end
    end

    context 'when multiple report formats are specified' do
      it 'returns two Reports with default and specified targets where appropriate' do
        reports = described_class.report_formats(['text', 'junit:foo.junit'])
        expect(reports.length).to eq(2)
        expect(reports[0].instance_variable_get(:@path)).to eq('stdout')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
        expect(reports[1].instance_variable_get(:@path)).to eq('foo.junit')
        expect(reports[1].instance_variable_get(:@format)).to eq('junit')
      end
    end
  end

  context 'when normalising parameter specifications' do
    subject { described_class.parameter_specification(param_spec) }

    let(:param_name) { 'test_param' }
    let(:param_type) { nil }
    let(:param_spec) { [param_name, param_type].compact.join(':') }

    context 'when passed a parameter with a simple data type' do
      let(:param_type) { 'Integer' }

      before(:each) do
        expect(PDK::CLI::Util::OptionValidator).to receive(:is_valid_param_name?).with(param_name).and_call_original
        expect(PDK::CLI::Util::OptionValidator).to receive(:is_valid_data_type?).with(param_type).and_call_original
      end

      it { is_expected.to eq(name: param_name, type: param_type) }
    end

    context 'when passed a parameter without a data type' do
      before(:each) do
        expect(PDK::CLI::Util::OptionValidator).to receive(:is_valid_param_name?).with(param_name).and_call_original
      end

      it 'defaults to a String data type' do
        is_expected.to eq(name: param_name, type: 'String')
      end
    end

    context 'when passed a parameter with an abstract data type' do
      let(:param_type) { 'Variant[Enum["absent", "present"], Integer]' }

      before(:each) do
        expect(PDK::CLI::Util::OptionValidator).to receive(:is_valid_param_name?).with(param_name).and_call_original
        expect(PDK::CLI::Util::OptionValidator).to receive(:is_valid_data_type?).with(param_type).and_call_original
      end

      it { is_expected.to eq(name: param_name, type: param_type) }
    end

    context 'when passed an invalid parameter name' do
      before(:each) do
        allow(PDK::CLI::Util::OptionValidator).to receive(:is_valid_param_name?).with(param_name).and_return(false)
      end

      it { expect { subject }.to raise_error(PDK::CLI::FatalError, %r{'#{param_name}' is not a valid parameter name}) }
    end

    context 'when passed an invalid data type' do
      let(:param_type) { 'integer' }

      before(:each) do
        allow(PDK::CLI::Util::OptionValidator).to receive(:is_valid_data_type?).with(param_type).and_return(false)
      end

      it { expect { subject }.to raise_error(PDK::CLI::FatalError, %r{'#{param_type}' is not a valid data type}) }
    end
  end
end

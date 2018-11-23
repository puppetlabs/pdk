require 'spec_helper'

describe PDK::Validate::TasksValidator do
  let(:report) { PDK::Report.new }

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, {}) }

    context 'when the metadata validator succeeds' do
      before(:each) do
        allow(PDK::Validate::Tasks::MetadataLint).to receive(:invoke).with(report, anything).and_return(0)
      end

      it 'returns 0' do
        expect(return_value).to eq(0)
      end
    end

    context 'when the metadata validator fails' do
      before(:each) do
        allow(PDK::Validate::Tasks::MetadataLint).to receive(:invoke).with(report, anything).and_return(1)
      end

      it 'returns 1' do
        expect(return_value).to eq(1)
      end
    end
  end
end

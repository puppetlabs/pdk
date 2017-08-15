require 'spec_helper'

describe PDK::Validate::MetadataValidator do
  let(:report) { PDK::Report.new }

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, {}) }

    context 'when the MetadataSyntax validator fails' do
      before(:each) do
        allow(PDK::Validate::MetadataSyntax).to receive(:invoke).with(report, anything).and_return(1)
      end

      it 'does not run the MetadataJSONLint validator and returns 1' do
        expect(PDK::Validate::MetadataJSONLint).not_to receive(:invoke)
        expect(return_value).to eq(1)
      end
    end

    context 'when the MetadataSyntax validator succeeds' do
      before(:each) do
        allow(PDK::Validate::MetadataSyntax).to receive(:invoke).with(report, anything).and_return(0)
      end

      context 'and the MetadataJSONLint validator fails' do
        before(:each) do
          allow(PDK::Validate::MetadataJSONLint).to receive(:invoke).with(report, anything).and_return(1)
        end

        it 'returns 1' do
          expect(return_value).to eq(1)
        end
      end

      context 'and the MetadataJSONLint validator succeeds' do
        before(:each) do
          allow(PDK::Validate::MetadataJSONLint).to receive(:invoke).with(report, anything).and_return(0)
        end

        it 'returns 0' do
          expect(return_value).to eq(0)
        end
      end
    end
  end

  describe '.invoke with targets' do
    subject(:invoke_with_targets) { described_class.invoke(report, targets: %w[foo bar]) }

    before(:each) do
      allow(PDK::Validate::MetadataSyntax).to receive(:invoke).with(report, anything).and_return(1)
      allow(PDK::Validate::MetadataJSONLint).to receive(:invoke).with(report, anything).and_return(1)
    end

    it 'informs user that explicit targets were invalid' do
      expect(invoke_with_targets).to eq(1)
    end
  end
end

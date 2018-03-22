# frozen_string_literal: true

require 'spec_helper'

describe PDK::Validate::PuppetValidator do
  let(:report) { PDK::Report.new }

  describe '.invoke' do
    subject(:return_value) { described_class.invoke(report, {}) }

    context 'when the PuppetSyntax validator fails' do
      before(:each) do
        allow(PDK::Validate::PuppetSyntax).to receive(:invoke).with(report, anything).and_return(1)
      end

      it 'does not run the PuppetLint validator and returns 1' do
        expect(PDK::Validate::PuppetLint).not_to receive(:invoke)
        expect(return_value).to eq(1)
      end
    end

    context 'when the PuppetSyntax validator succeeds' do
      before(:each) do
        allow(PDK::Validate::PuppetSyntax).to receive(:invoke).with(report, anything).and_return(0)
      end

      context 'and the PuppetLint validator fails' do
        before(:each) do
          allow(PDK::Validate::PuppetLint).to receive(:invoke).with(report, anything).and_return(1)
        end

        it 'returns 1' do
          expect(return_value).to eq(1)
        end
      end

      context 'and the PuppetLint validator succeeds' do
        before(:each) do
          allow(PDK::Validate::PuppetLint).to receive(:invoke).with(report, anything).and_return(0)
        end

        it 'returns 0' do
          expect(return_value).to eq(0)
        end
      end
    end
  end
end

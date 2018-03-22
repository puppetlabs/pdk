# frozen_string_literal: true

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
    context 'and given a single format with no target' do
      it 'returns a single format specification with default target' do
        reports = described_class.report_formats(['text'])
        expect(reports.length).to eq(1)
        expect(reports[0][:method]).to eq(:write_text)
        expect(reports[0][:target]).to eq(PDK::Report.default_target)
      end
    end

    context 'and given a single format with a target' do
      it 'returns a single format specification with target' do
        reports = described_class.report_formats(['text:foo.txt'])
        expect(reports.length).to eq(1)
        expect(reports[0][:method]).to eq(:write_text)
        expect(reports[0][:target]).to eq('foo.txt')
      end

      context 'and the target is stdout' do
        it 'returns the $stdout IO object as the target' do
          reports = described_class.report_formats(['text:stdout'])
          expect(reports.length).to eq(1)
          expect(reports[0][:method]).to eq(:write_text)
          expect(reports[0][:target]).to eq($stdout)
        end
      end

      context 'and the target is stderr' do
        it 'returns the $stderr IO object as the target' do
          reports = described_class.report_formats(['text:stderr'])
          expect(reports.length).to eq(1)
          expect(reports[0][:method]).to eq(:write_text)
          expect(reports[0][:target]).to eq($stderr)
        end
      end
    end

    context 'and multiple report formats are specified' do
      it 'returns multiple format specifications with targets when appropriate' do
        reports = described_class.report_formats(['text', 'junit:foo.junit'])
        expect(reports.length).to eq(2)
        expect(reports[0][:method]).to eq(:write_text)
        expect(reports[0][:target]).to eq(PDK::Report.default_target)
        expect(reports[1][:method]).to eq(:write_junit)
        expect(reports[1][:target]).to eq('foo.junit')
      end
    end
  end
end

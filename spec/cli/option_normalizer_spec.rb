require 'spec_helper'
require 'pdk/cli/util/option_normalizer'

describe PDK::CLI::Util::OptionNormalizer do
  context 'when parsing report formats and targets' do

    context 'when a single format is specified' do
      it 'should return a single Report with the default target when target is not specified' do
        reports = described_class.report_formats(['text'])
        expect(reports.length).to eq(1)
        expect(reports[0].instance_variable_get(:@path)).to eq('stdout')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
      end

      it 'should return a single Report with the specified target when provided' do
        reports = described_class.report_formats(['text:foo.txt'])
        expect(reports.length).to eq(1)
        expect(reports[0].instance_variable_get(:@path)).to eq('foo.txt')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
      end
    end

    context 'when multiple report formats are specified' do
      it 'should return two Reports with default and specified targets where appropriate' do
        reports = described_class.report_formats(['text', 'junit:foo.junit'])
        expect(reports.length).to eq(2)
        expect(reports[0].instance_variable_get(:@path)).to eq('stdout')
        expect(reports[0].instance_variable_get(:@format)).to eq('text')
        expect(reports[1].instance_variable_get(:@path)).to eq('foo.junit')
        expect(reports[1].instance_variable_get(:@format)).to eq('junit')
      end
    end
  end
end

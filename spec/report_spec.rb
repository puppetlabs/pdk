require 'spec_helper'

describe Pick::Report do
  it 'should include formats junit and text' do
    expect(Pick::Report.formats).to eq(%w(junit text))
  end

  it 'should have a default format of junit' do
    expect(Pick::Report.default_format).to eq('junit')
  end

  context 'when no format is specified' do
    let(:report) { Pick::Report.new('foo') }

    it 'should instantiate its format to junit' do
      expect(report).to receive(:prepare_junit).with('cmd output')
      report.write('cmd output')
    end
  end

  context 'when a format is specified' do
    let(:report) { Pick::Report.new('foo', 'text') }

    it 'should instantiate its format to text' do
      expect(report).to receive(:prepare_text).with('cmd output')
      report.write('cmd output')
    end
  end
end

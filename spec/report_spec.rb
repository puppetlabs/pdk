require 'spec_helper'
require 'tmpdir'

describe Pick::Report do
  def tmpdir
    @tmpdir ||= Dir.mktmpdir
  end

  after(:each) do
    FileUtils.remove_entry_secure(@tmpdir) if @tmpdir
  end

  it 'should include formats junit and text' do
    expect(Pick::Report.formats).to eq(%w(junit text))
  end

  it 'should have a default format of junit' do
    expect(Pick::Report.default_format).to eq('junit')
  end

  context 'when no format is specified' do
    let(:report) { Pick::Report.new(File.join(tmpdir, 'report')) }

    it 'should instantiate its format to junit' do
      expect(report).to receive(:prepare_junit).with('cmd output')
      report.write('cmd output')
    end
  end

  context 'when a format is specified' do
    let(:report) { Pick::Report.new(File.join(tmpdir, 'report.txt'), 'text') }

    it 'should instantiate its format to text' do
      expect(report).to receive(:prepare_text).with('cmd output')
      report.write('cmd output')
    end
  end
end

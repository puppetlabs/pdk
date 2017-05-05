require 'spec_helper'
require 'tmpdir'

describe PDK::Report do
  let(:tmpdir) { Dir.mktmpdir }

  after do
    FileUtils.remove_entry_secure(tmpdir) if tmpdir
  end

  it 'includes formats junit and text' do
    expect(described_class.formats).to eq(%w[junit text])
  end

  it 'has a default format of junit' do
    expect(described_class.default_format).to eq('junit')
  end

  context 'when no format is specified' do
    let(:report) { described_class.new(File.join(tmpdir, 'report')) }

    it 'instantiates its format to junit' do
      allow(report).to receive(:prepare_junit)
      report.write('cmd output')
      expect(report).to have_received(:prepare_junit).with('cmd output')
    end
  end

  context 'when a format is specified' do
    let(:report) { described_class.new(File.join(tmpdir, 'report.txt'), 'text') }

    it 'instantiates its format to text' do
      allow(report).to receive(:prepare_text)
      report.write('cmd output')
      expect(report).to have_received(:prepare_text).with('cmd output')
    end
  end
end

require 'spec_helper'

describe PDK::Module::TemplateDir::PlainEngine do
  subject { described_class }
  let(:path) { '/path/to/some/file' }


  it { is_expected.to respond_to(:render).with(2).arguments }

  context 'when asked to render a file that exists' do
    it 'should return the contents of the file' do
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readable?).with(path).and_return(true)
      expect(File).to receive(:read).with(path).and_return("some content")

      expect(subject.render(path, {})).to eq("some content")
    end
  end

  context 'when asked to render a file that does not exist' do
    it 'should return nil' do
      expect(File).to receive(:file?).with(path).and_return(false)
      expect(subject.render(path, {})).to be nil
    end
  end

  context 'when asked to render a file that exists but is unreadable' do
    it 'should return nil' do
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readable?).with(path).and_return(false)
      expect(subject.render(path, {})).to be nil
    end
  end
end

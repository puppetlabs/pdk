require 'spec_helper'

describe PDK::Module::TemplateDir::ERBEngine do
  subject { described_class }
  let(:path) { '/path/to/some/file' }
  let(:data) { {:configs => {'test' => 'value'}, :some => 'value'} }

  it { is_expected.to respond_to(:render).with(2).arguments }

  context 'when asked to render a file that exists' do
    before(:each) do
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readable?).with(path).and_return(true)
    end

    it 'should render the contents of the file as an ERB template' do
      expect(File).to receive(:read).with(path).and_return("<%= some %>")
      expect(subject.render(path, data)).to eq(data[:some])
    end

    # modulesync compatibility
    it 'should provide any data provided as "configs" to the template as an instance variable' do
      expect(File).to receive(:read).with(path).and_return("<%= @configs['test'] %>")
      expect(subject.render(path, data)).to eq(data[:configs]['test'])
    end
  end

  context 'when asked to render a file that does not exist' do
    it 'should return nil' do
      expect(File).to receive(:file?).with(path).and_return(false)
      expect(subject.render(path, data)).to be nil
    end
  end

  context 'when asked to render a file that exists but is unreadable' do
    it 'should return nil' do
      expect(File).to receive(:file?).with(path).and_return(true)
      expect(File).to receive(:readable?).with(path).and_return(false)
      expect(subject.render(path, data)).to be nil
    end
  end
end

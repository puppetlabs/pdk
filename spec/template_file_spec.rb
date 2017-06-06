require 'spec_helper'

describe PDK::TemplateFile do
  subject { described_class.new(template_path, data) }

  let(:data) { { configs: { 'test' => 'value' }, some: 'value' } }

  context 'when asked to render a file' do
    let(:template_path) { '/path/to/some/file' }

    context 'that exists' do
      before(:each) do
        expect(File).to receive(:file?).with(template_path).and_return(true)
        expect(File).to receive(:readable?).with(template_path).and_return(true)
      end

      context 'and has an .erb extension' do
        let(:template_path) { '/path/to/some/file.erb' }

        it 'renders the contents of the file as an ERB template' do
          expect(File).to receive(:read).with(template_path).and_return('<%= some %>')
          expect(subject.render).to eq(data[:some])
        end

        # modulesync compatibility
        it 'exposes any data provided as :configs to the template as an instance variable' do
          expect(File).to receive(:read).with(template_path).and_return("<%= @configs['test'] %>")
          expect(subject.render).to eq(data[:configs]['test'])
        end
      end

      context 'and does not have an .erb extension' do
        it 'renders the contents of the file as a plain file' do
          expect(File).to receive(:read).with(template_path).and_return('some content')
          expect(subject.render).to eq('some content')
        end
      end
    end

    context 'that does not exist' do
      it 'raises an ArgumentError' do
        expect(File).to receive(:file?).with(template_path).and_return(false)
        expect { subject.render }.to raise_error(ArgumentError, "'#{template_path}' is not a readable file")
      end
    end

    context 'that exists but is not readable' do
      it 'raises an ArgumentError' do
        expect(File).to receive(:file?).with(template_path).and_return(true)
        expect(File).to receive(:readable?).with(template_path).and_return(false)
        expect { subject.render }.to raise_error(ArgumentError, "'#{template_path}' is not a readable file")
      end
    end
  end
end

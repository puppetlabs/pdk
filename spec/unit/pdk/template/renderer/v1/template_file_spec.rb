require 'spec_helper'
require 'pdk/template/renderer/v1/template_file'

describe PDK::Template::Renderer::V1::TemplateFile do
  subject(:template_file) { described_class.new(template_path, data) }

  let(:data) { { configs: { 'test' => 'value' }, some: 'value' } }

  context '#config_for' do
    subject { template_file.config_for(filename) }

    let(:filename) { 'testfile' }
    let(:template_path) { '/path/to/some/file' }

    context 'when :template_dir not passed in the data hash' do
      it { is_expected.to be_nil }
    end

    context 'when :template_dir has been passed in the data hash' do
      let(:data) do
        {
          configs: { 'test' => 'value' },
          template_dir: instance_double(PDK::Template::Renderer::V1::LegacyTemplateDir),
        }
      end

      before(:each) do
        allow(data[:template_dir]).to receive(:config_for).with(filename).and_return(a: 'value')
      end

      it { is_expected.to eq(a: 'value') }
    end
  end

  context 'when asked to render a file' do
    let(:template_path) { '/path/to/some/file' }

    context 'that exists' do
      before(:each) do
        allow(PDK::Util::Filesystem).to receive(:file?).with(template_path).and_return(true)
        expect(PDK::Util::Filesystem).to receive(:readable?).with(template_path).and_return(true)
      end

      context 'and has an .erb extension' do
        let(:template_path) { '/path/to/some/file.erb' }

        it 'renders the contents of the file as an ERB template' do
          expect(PDK::Util::Filesystem).to receive(:read_file).with(template_path).and_return('<%= some %>')
          expect(template_file.render).to eq(data[:some])
        end

        # modulesync compatibility
        it 'exposes any data provided as :configs to the template as an instance variable' do
          expect(PDK::Util::Filesystem).to receive(:read_file).with(template_path).and_return("<%= @configs['test'] %>")
          expect(template_file.render).to eq(data[:configs]['test'])
        end
      end

      context 'and does not have an .erb extension' do
        it 'renders the contents of the file as a plain file' do
          expect(PDK::Util::Filesystem).to receive(:read_file).with(template_path).and_return('some content')
          expect(template_file.render).to eq('some content')
        end
      end
    end

    context 'that does not exist' do
      it 'raises an ArgumentError' do
        allow(PDK::Util::Filesystem).to receive(:file?).with(template_path).and_return(false)
        expect { template_file.render }.to raise_error(ArgumentError, "'#{template_path}' is not a readable file")
      end
    end

    context 'that exists but is not readable' do
      it 'raises an ArgumentError' do
        allow(PDK::Util::Filesystem).to receive(:file?).with(template_path).and_return(true)
        expect(PDK::Util::Filesystem).to receive(:readable?).with(template_path).and_return(false)
        expect { template_file.render }.to raise_error(ArgumentError, "'#{template_path}' is not a readable file")
      end
    end
  end
end

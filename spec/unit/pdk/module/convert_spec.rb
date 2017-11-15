require 'spec_helper'
require 'pdk/module/convert'

describe PDK::Module::Convert do
  shared_examples_for 'it interviews the user for the metadata' do
    it 'interviews the user for the metadata' do
      expect(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      described_class.update_metadata(metadata_path, template_metadata)
    end

    it 'updates the metadata with information about the template used to convert the module' do
      allow(PDK::Generate::Module).to receive(:prepare_metadata).and_return(PDK::Module::Metadata.new)
      expect(updated_metadata).to include('template-url' => 'http://my.test/template.git', 'template-ref' => 'v1.2.3')
    end
  end

  describe '.update_metadata' do
    subject(:updated_metadata) do
      described_class.update_metadata(metadata_path, template_metadata)
      new_metadata_file.rewind
      JSON.parse(new_metadata_file.read)
    end

    let(:metadata_path) { 'metadata.json' }
    let(:template_metadata) do
      {
        'template-url' => 'http://my.test/template.git',
        'template-ref' => 'v1.2.3',
      }
    end
    let(:new_metadata_file) { StringIO.new }

    before(:each) do
      allow(File).to receive(:open).with(any_args).and_call_original
      allow(File).to receive(:open).with("#{metadata_path}.pdknew", 'w').and_yield(new_metadata_file)
    end

    context 'when the metadata file exists' do
      before(:each) do
        allow(File).to receive(:exist?).with(metadata_path).and_return(true)
      end

      context 'and is a file' do
        before(:each) do
          allow(File).to receive(:file?).with(metadata_path).and_return(true)
        end

        context 'and is readable' do
          before(:each) do
            allow(File).to receive(:readable?).with(metadata_path).and_return(true)
            allow(File).to receive(:read).with(metadata_path).and_return(existing_metadata)
          end

          let(:existing_metadata) do
            {
              'name' => 'testuser-testmodule',
            }.to_json
          end

          it 'reads the existing metadata from the file' do
            expect(updated_metadata).to include('name' => 'testuser-testmodule')
          end

          it 'updates the metadata to include the missing keys from the module generation defaults' do
            expect(updated_metadata).to include('license' => 'Apache-2.0')
          end

          it 'updates the metadata with information about the template used to convert the module' do
            expect(updated_metadata).to include('template-url' => 'http://my.test/template.git', 'template-ref' => 'v1.2.3')
          end

          context 'but contains invalid JSON' do
            let(:existing_metadata) { '' }

            it_behaves_like 'it interviews the user for the metadata'
          end
        end

        context 'and is not readable' do
          before(:each) do
            allow(File).to receive(:readable?).with(metadata_path).and_return(false)
          end

          it 'exits with an error' do
            expect {
              described_class.update_metadata(metadata_path, template_metadata)
            }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not readable})
          end
        end
      end

      context 'and is not a file' do
        before(:each) do
          allow(File).to receive(:file?).with(metadata_path).and_return(false)
        end

        it 'exits with an error' do
          expect {
            described_class.update_metadata(metadata_path, template_metadata)
          }.to raise_error(PDK::CLI::ExitWithError, %r{exists but it is not a file})
        end
      end
    end

    context 'when the metadata file does not exist' do
      it_behaves_like 'it interviews the user for the metadata'
    end
  end
end

require 'spec_helper'

describe PDK::Module::Metadata do
  context '.from_file' do
    let(:metadata_json_path) { '/tmp/metadata.json' }
    let(:metadata_json_content) do
      {
        'name' => 'foo-bar',
        'version' => '0.1.0',
      }.to_json
    end

    it 'can populate itself from a metadata.json file on disk' do
      allow(File).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(File).to receive(:readable?).with(metadata_json_path).and_return(true)
      allow(File).to receive(:read).with(metadata_json_path).and_return(metadata_json_content)

      expect(described_class.from_file(metadata_json_path).data).to include({'name' => 'foo-bar', 'version' => '0.1.0'})
    end

    it 'raises an ArgumentError if the file does not exist' do
      allow(File).to receive(:file?).with(metadata_json_path).and_return(false)
      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, /'#{metadata_json_path}'.*not exist/)
    end

    it 'raises an ArgumentError if the file exists but is not readable' do
      allow(File).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(File).to receive(:readable?).with(metadata_json_path).and_return(false)

      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, /Unable to open '#{metadata_json_path}'/)
    end

    it 'raises an ArgumentError if the file contains invalid JSON' do
      allow(File).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(File).to receive(:readable?).with(metadata_json_path).and_return(true)
      allow(File).to receive(:read).with(metadata_json_path).and_return('{"foo": }')

      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, /Invalid JSON.*unexpected token/)
    end
  end

  context 'when processing and validating metadata' do
    let (:metadata) { PDK::Module::Metadata.new.update!(
                        'name' => 'foo-bar',
                        'version' => '0.1.0',
                        'dependencies' => [
                          { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }
                        ]
                      )
                    }

    it 'should error when the provided name is not namespaced' do
      expect { metadata.update!({'name' => 'foo'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the field must be a dash-separated username and module name")
    end

    it 'should error when the provided name contains non-alphanumeric characters' do
      expect { metadata.update!({'name' => 'foo-@bar'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the module name contains non-alphanumeric (or underscore) characters")
    end

    it 'should error when the provided name starts with a non-letter character' do
      expect { metadata.update!({'name' => 'foo-1bar'}) }.to raise_error(ArgumentError, "Invalid 'name' field in metadata.json: the module name must begin with a letter")
    end
  end
end

require 'spec_helper'
require 'pdk/module/metadata'

describe PDK::Module::Metadata do
  describe '.from_file' do
    let(:metadata_json_path) { '/tmp/metadata.json' }
    let(:metadata_json_content) do
      {
        'name' => 'foo-bar',
        'version' => '0.1.0',
      }.to_json
    end

    before(:each) do
      allow(PDK::Util).to receive(:package_install?).and_return(true)
    end

    it 'can populate itself from a metadata.json file on disk' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_json_path).and_return(true)
      allow(PDK::Util).to receive(:package_install?).and_return(false)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(metadata_json_path).and_return(metadata_json_content)

      expect(described_class.from_file(metadata_json_path).data).to include('name' => 'foo-bar', 'version' => '0.1.0')
    end

    it 'can populate itself from a metadata.json file on disk with a trailing newline' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(metadata_json_path).and_return(metadata_json_content + "\n")

      expect(described_class.from_file(metadata_json_path).data).to include('name' => 'foo-bar', 'version' => '0.1.0')
    end

    it 'raises an ArgumentError if passed nil' do
      expect { described_class.from_file(nil) }.to raise_error(ArgumentError, %r{no path to file}i)
    end

    it 'raises an ArgumentError if the file does not exist' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_json_path).and_return(false)
      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, %r{'#{metadata_json_path}'.*not exist})
    end

    it 'raises an ArgumentError if the file exists but is not readable' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_json_path).and_return(false)

      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, %r{Unable to open '#{metadata_json_path}'})
    end

    it 'raises an ArgumentError if the file contains invalid JSON' do
      allow(PDK::Util::Filesystem).to receive(:file?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:readable?).with(metadata_json_path).and_return(true)
      allow(PDK::Util::Filesystem).to receive(:read_file).with(metadata_json_path).and_return('{"foo": }')

      expect { described_class.from_file(metadata_json_path) }.to raise_error(ArgumentError, %r{Invalid JSON})
    end
  end

  context 'when processing and validating metadata' do
    let(:metadata) do
      described_class.new.update!(
        'name' => 'foo-bar',
        'version' => '0.1.0',
        'dependencies' => [
          { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' },
        ],
      )
    end

    it 'errors when the provided name is not namespaced' do
      expect { metadata.update!('name' => 'foo') }.to raise_error(ArgumentError, %r{Invalid 'name' field in metadata.json: field must be a dash-separated user name and module name}i)
    end

    it 'errors when the provided name contains non-alphanumeric characters' do
      expect { metadata.update!('name' => 'foo-@bar') }.to raise_error(ArgumentError, %r{Invalid 'name' field in metadata.json: module name must contain only alphanumeric or underscore characters}i)
    end

    it 'errors when the provided name starts with a non-letter character' do
      expect { metadata.update!('name' => 'foo-1bar') }.to raise_error(ArgumentError, %r{Invalid 'name' field in metadata.json: module name must begin with a letter}i)
    end

    it 'converts user/module style names to user-module' do
      metadata.update!('name' => 'user/module')

      expect(metadata.data['name']).to eq('user-module')
    end
  end

  describe '#forge_ready?' do
    subject { described_class.new(metadata).forge_ready? }

    context 'when the metadata contains all the required fields' do
      let(:metadata) do
        {
          'name' => 'test-module',
          'version' => '0.1.0',
          'author' => 'Test User',
          'summary' => 'This module is amazing. Really.',
          'license' => 'Apache-2.0',
          'source' => 'https://github.com/puppetlabs/test-module',
          'project_page' => 'https://github.com/puppetlabs/test-module',
          'issues_url' => 'https://github.com/puppetlabs/test-module/issues',
          'dependencies' => [],
          'operatingsystem_support' => [
            {
              'operatingsystem' => 'Debian',
              'operatingsystemrelease' => ['10'],
            },
          ],
          'requirements' => [
            {
              'name' => 'puppet',
              'version_requirement' => '>= 4.7.0 < 6.0.0',
            },
          ],
        }
      end

      it { is_expected.to be_truthy }
    end

    context 'when the metadata is missing fields' do
      let(:metadata) do
        {
          'name' => 'test-module',
          'version' => '0.1.0',
        }
      end

      it { is_expected.to be_falsey }
    end
  end

  describe '#interview_for_forge!' do
    let(:metadata_instance) { described_class.new(metadata) }

    after(:each) do
      metadata_instance.interview_for_forge!
    end

    context 'when the metadata is missing fields' do
      let(:metadata) do
        {
          'name' => 'test-module',
          'version' => '0.1.0',
          'author' => 'Test User',
          'summary' => 'This module is amazing. Really.',
          'license' => 'Apache-2.0',
          'project_page' => 'https://github.com/puppetlabs/test-module',
          'issues_url' => 'https://github.com/puppetlabs/test-module/issues',
          'dependencies' => [],
          'operatingsystem_support' => [
            {
              'operatingsystem' => 'Debian',
              'operatingsystemrelease' => ['10'],
            },
          ],
          'requirements' => [
            {
              'name' => 'puppet',
              'version_requirement' => '>= 4.7.0 < 6.0.0',
            },
          ],
        }
      end

      it 'interviews the user for only the missing fields' do
        expect(PDK::Generate::Module).to receive(:module_interview).with(metadata_instance, only_ask: ['source'])
      end
    end
  end

  describe '#validate_puppet_version_requirement!' do
    let(:metadata) { described_class.new }

    context 'when the metadata contains a puppet requirement with a version_requirement' do
      it 'does not raise an error' do
        expect {
          metadata.validate_puppet_version_requirement!
        }.not_to raise_error
      end
    end

    context 'when the metadata does not contain any requirements' do
      before(:each) do
        metadata.data.delete('requirements')
      end

      it 'raises an ArgumentError' do
        expect {
          metadata.validate_puppet_version_requirement!
        }.to raise_error(ArgumentError, %r{does not contain any requirements}i)
      end
    end

    context 'when the metadata does not contain a puppet requirement' do
      before(:each) do
        metadata.data['requirements'] = [{ 'name' => 'not_puppet', 'version_requirement' => '1.0.0' }]
      end

      it 'raises an ArgumentError' do
        expect {
          metadata.validate_puppet_version_requirement!
        }.to raise_error(ArgumentError, %r{does not contain a "puppet" requirement}i)
      end
    end

    context 'when the puppet requirement does not have a version_requirement' do
      before(:each) do
        metadata.data['requirements'] = [{ 'name' => 'puppet' }]
      end

      it 'raises an ArgumentError' do
        expect {
          metadata.validate_puppet_version_requirement!
        }.to raise_error(ArgumentError, %r{does not specify a "version_requirement"}i)
      end
    end

    context 'when the puppet requirement has a blank version_requirement' do
      before(:each) do
        metadata.data['requirements'] = [{ 'name' => 'puppet', 'version_requirement' => '' }]
      end

      it 'raises an ArgumentError' do
        expect {
          metadata.validate_puppet_version_requirement!
        }.to raise_error(ArgumentError, %r{does not specify a "version_requirement"}i)
      end
    end
  end

  describe '#write!' do
    let(:metadata_json_path) { '/tmp/metadata.json' }

    let(:metadata) do
      described_class.new.update!(
        'name' => 'foo-bar',
        'version' => '0.1.0',
      )
    end

    it 'writes the metadata to disk' do
      expect(PDK::Util::Filesystem).to receive(:write_file)
        .with(metadata_json_path, satisfy { |content| JSON.parse(content)['name'] == 'foo-bar' })

      metadata.write!(metadata_json_path)
    end
  end
end

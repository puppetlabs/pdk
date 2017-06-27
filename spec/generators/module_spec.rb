require 'spec_helper'

describe PDK::Generate::Module do
  context 'when gathering module information via the user interview' do
    let(:metadata) do
      PDK::Module::Metadata.new.update!(
        'version' => '0.1.0',
        'dependencies' => [
          { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' },
        ],
      )
    end

    it 'populates the Metadata object based on user input' do
      allow(STDOUT).to receive(:puts)
      expect(PDK::CLI::Input).to receive(:get) { 'foo' }
      expect(PDK::CLI::Input).to receive(:get) { '2.2.0' }
      expect(PDK::CLI::Input).to receive(:get) { 'William Hopper' }
      expect(PDK::CLI::Input).to receive(:get) { 'Apache-2.0' }
      expect(PDK::CLI::Input).to receive(:get) { 'A simple module to do some stuff.' }
      expect(PDK::CLI::Input).to receive(:get) { 'github.com/whopper/bar' }
      expect(PDK::CLI::Input).to receive(:get) { 'forge.puppet.com/whopper/bar' }
      expect(PDK::CLI::Input).to receive(:get) { 'tickets.foo.com/whopper/bar' }
      expect(PDK::CLI::Input).to receive(:get) { 'yes' }

      described_class.module_interview(metadata, name: 'bar')

      expect(metadata.data).to eq(
        'name' => 'foo-bar',
        'version'       => '2.2.0',
        'author'        => 'William Hopper',
        'license'       => 'Apache-2.0',
        'summary'       => 'A simple module to do some stuff.',
        'source'        => 'github.com/whopper/bar',
        'project_page'  => 'forge.puppet.com/whopper/bar',
        'issues_url'    => 'tickets.foo.com/whopper/bar',
        'dependencies'  => [{ 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 1.0.0' }],
        'data_provider' => nil,
        'operatingsystem_support' => [
          { 'operatingsystem' => 'Debian', 'operatingsystemrelease' => ['8'] },
          { 'operatingsystem' => 'RedHat', 'operatingsystemrelease' => ['7.0'] },
          { 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['16.04'] },
          { 'operatingsystem' => 'Windows', 'operatingsystemrelease' => ['2016'] },
        ],
      )
    end
  end

  context 'when running under a user whose name is not a valid forge name' do
    before(:each) do
      allow(Etc).to receive(:getlogin).and_return('user.name')
    end

    let(:defaults) do
      {
        :name => 'foo',
        :'skip-interview' => true,
        :target_dir => 'foo',
      }
    end

    it 'still works' do
      expect { described_class.prepare_metadata(defaults) }.not_to raise_error
    end

    describe 'the generated metadata' do
      subject(:the_metadata) { described_class.prepare_metadata(defaults).data }

      it do
        expect(the_metadata['name']).to eq 'username-foo'
      end
    end

    context 'when running under an entirely non-alphanumeric username' do
      before(:each) do
        allow(Etc).to receive(:getlogin).and_return('Αρίσταρχος ό Σάμιος')
      end

      let(:defaults) do
        {
          :name => 'foo',
          :'skip-interview' => true,
          :target_dir => 'foo',
        }
      end

      it 'still works' do
        expect { described_class.prepare_metadata(defaults) }.not_to raise_error
      end

      describe 'the generated metadata' do
        subject(:the_metadata) { described_class.prepare_metadata(defaults).data }

        it do
          expect(the_metadata['name']).to eq 'username-foo'
        end
      end
    end
  end


  context '.prepare_module_directory' do
    let(:path) { 'test123' }

    it 'creates a skeleton directory structure' do
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'manifests'))
      expect(FileUtils).to receive(:mkdir_p).with(File.join(path, 'templates'))

      described_class.prepare_module_directory(path)
    end
  end
end

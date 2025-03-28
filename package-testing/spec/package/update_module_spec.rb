require 'spec_helper_package'
require 'open-uri'
require 'json'

modules = [
  'puppetlabs/puppetlabs-motd'
]

describe 'Updating an existing module' do
  modules.each do |mod|
    context "when updating #{mod}" do
      metadata = JSON.parse(URI.open("https://raw.githubusercontent.com/#{mod}/main/metadata.json").read)
      metadata['template-url'] = 'pdk-default#main'
      repo_dir = File.join(home_dir, metadata['name'])

      describe command("#{git_bin} clone https://github.com/#{mod} #{repo_dir}") do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk update --force') do
        before(:all) do
          module_dir = File.join(home_dir(true), metadata['name'])
          create_remote_file(get_working_node, File.join(module_dir, 'metadata.json'), metadata.to_json)

          sync_yaml = YAML.safe_load(URI.open("https://raw.githubusercontent.com/#{mod}/main/.sync.yml").read)
          create_remote_file(get_working_node, File.join(module_dir, '.sync.yml'), sync_yaml.to_yaml)
        end

        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk validate') do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0).or eq(1) }

        context 'stdout lines' do
          subject { super().stdout.split("\n") }

          it 'does not output any unexpected errors' do
            expect(subject).to all(match(/\((?:convention|info|warning|error)\): (?:puppet-lint|rubocop|task-metadata-lint|task-name|puppet-epp)/i))
          end
        end
      end

      describe command('pdk test unit') do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }

        its(:stdout) { is_expected.to match(/0 failures/m) } unless windows_node?
      end

      # Parallel tests gem is currently broken on Windows.
      describe command('pdk test unit --parallel'), unless: windows_node? do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(/0 failures/m) }
      end

      describe command('pdk build --force') do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }
      end

      describe file(File.join(repo_dir, 'pkg', "#{metadata['name']}-#{metadata['version']}.tar.gz")) do
        it { is_expected.to be_file }
      end
    end
  end
end

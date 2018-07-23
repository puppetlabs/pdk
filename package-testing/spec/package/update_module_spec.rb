require 'spec_helper_package'
require 'open-uri'
require 'json'

modules = [
  'puppetlabs/puppetlabs-motd',
  'puppetlabs/puppetlabs-concat',
  'puppetlabs/puppetlabs-inifile',
]

describe 'Updating an existing module' do
  modules.each do |mod|
    context "when updating #{mod}" do
      metadata = JSON.parse(open("https://raw.githubusercontent.com/#{mod}/master/metadata.json").read)
      metadata['template-url'] = "file://#{File.join(install_dir, 'share', 'cache', 'pdk-templates.git')}"
      repo_dir = File.join(home_dir, metadata['name'])

      describe command("#{git_bin} clone https://github.com/#{mod} #{repo_dir}") do
        its(:exit_status) { is_expected.to eq(0) }
      end

      describe command('pdk update --force') do
        before(:all) do
          module_dir = File.join(home_dir(true), metadata['name'])
          create_remote_file(get_working_node, File.join(module_dir, 'metadata.json'), metadata.to_json)

          sync_yaml = YAML.safe_load(open("https://raw.githubusercontent.com/#{mod}/master/.sync.yml").read)
          sync_yaml['Gemfile']['required'][':system_tests'] << { 'gem' => 'nokogiri', 'version' => '1.8.2' }
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
            is_expected.to all(match(%r{^(?:info|warning|error): (?:puppet-lint|rubocop|task-metadata-lint)}))
          end
        end
      end

      describe command('pdk test unit') do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{0 failures}m) }
      end

      describe command('pdk test unit --parallel') do
        let(:cwd) { repo_dir }

        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{0 failures}m) }
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

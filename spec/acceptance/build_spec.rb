require 'spec_helper_acceptance'

describe 'pdk build', module_command: true do
  context 'when run inside of a module' do
    include_context 'in a new module', 'build'

    metadata = {
      'name'                    => 'testuser-build',
      'version'                 => '0.1.0',
      'author'                  => 'testuser',
      'summary'                 => 'a test module',
      'source'                  => 'https://github.com/testuser/puppet-build',
      'project_page'            => 'https://testuser.github.io/puppet-build',
      'issues_url'              => 'https://github.com/testuser/puppet-build/issues',
      'dependencies'            => [],
      'operatingsystem_support' => [{ 'operatingsystem' => 'windows', 'operatingsystemrelease' => ['10'] }],
      'requirements'            => [{ 'name' => 'puppet', 'version_requirement' => '> 4.10.0 < 7.0.0' }],
      'pdk-version'             => '1.2.3',
      'template-url'            => 'https://github.com/puppetlabs/pdk-templates',
      'template-ref'            => 'heads/master-0-g1234abc',
    }

    context 'when the module has complete metadata' do
      before(:all) do
        File.open('metadata.json', 'w') do |f|
          f.puts metadata.to_json
        end
      end

      after(:all) do
        FileUtils.remove_entry_secure('pkg')
      end

      describe command('pdk build --force') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.not_to match(%r{WARN|ERR}) }
        its(:stderr) { is_expected.to match(%r{Build of #{metadata['name']} has completed successfully}) }

        describe file(File.join('pkg', "#{metadata['name']}-#{metadata['version']}.tar.gz")) do
          it { is_expected.to be_file }
        end
      end
    end

    context 'when the module has incomplete metadata' do
      before(:all) do
        File.open('metadata.json', 'w') do |f|
          f.puts metadata.reject { |k, _| k == 'source' }.to_json
        end
      end

      after(:all) do
        FileUtils.remove_entry_secure('pkg')
      end

      describe command('pdk build --force') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
        its(:stderr) { is_expected.to match(%r{WARN.+missing the following fields.+source}) }
        its(:stderr) { is_expected.to match(%r{Build of #{metadata['name']} has completed successfully}) }

        describe file(File.join('pkg', "#{metadata['name']}-#{metadata['version']}.tar.gz")) do
          it { is_expected.to be_file }
        end
      end
    end
  end
end

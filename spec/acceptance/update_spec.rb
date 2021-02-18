require 'spec_helper_acceptance'

# Force the modules generated in these specs to use the public template repo to
# avoid unnecessary changes in the metadata.json during convert (template-url
# key).
template_repo = 'https://github.com/puppetlabs/pdk-templates'

describe 'pdk update', module_command: true do
  context 'when run inside of a module' do
    include_context 'in a new module', 'update', template: template_repo

    context 'that is already up to date' do
      describe command('pdk update') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to have_no_output }
        its(:stdout) { is_expected.to match(%r{No changes required.}i) }

        describe file('update_report.txt') do
          it { is_expected.not_to be_file }
        end
      end
    end

    context 'that is not up to date' do
      before(:all) do
        metadata = JSON.parse(File.read('metadata.json'))
        metadata['template-ref'] = 'heads/main-0-g1234567'

        File.open('metadata.json', 'w') do |f|
          f.puts metadata.to_json
        end
        FileUtils.rm('.travis.yml')
      end

      describe command('pdk update --noop') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{-+files to be added-+\n.*/\.travis\.yml}mi) }
        its(:stdout) { is_expected.to match(%r{-+files to be modified-+\n.*/metadata\.json}mi) }
        its(:stderr) { is_expected.to match(%r{updating \w+?-update using the default template}i) }

        describe file('update_report.txt') do
          it { is_expected.to be_file }
        end

        describe file('.travis.yml') do
          it { is_expected.not_to be_file }
        end
      end

      describe command('pdk update --force') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{-+files to be added-+\n.*/\.travis\.yml}mi) }
        its(:stdout) { is_expected.to match(%r{-+files to be modified-+\n.*/metadata\.json}mi) }
        its(:stderr) { is_expected.to match(%r{updating \w+?-update using the default template}i) }

        describe file('update_report.txt') do
          it { is_expected.to be_file }
        end

        describe file('.travis.yml') do
          it { is_expected.to be_file }
        end
      end
    end

    context 'that is missing an init-only templated file' do
      before(:all) do
        FileUtils.rm_f('README.md')
      end

      describe command('pdk update --force') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to have_no_output }
        its(:stdout) { is_expected.to match(%r{no changes required}i) }

        describe file('README.md') do
          it { is_expected.not_to be_file }
        end
      end
    end
  end
end

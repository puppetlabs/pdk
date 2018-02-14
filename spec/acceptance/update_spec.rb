require 'spec_helper_acceptance'

# Force the modules generated in these specs to use the public template repo to
# avoid unnecessary changes in the metadata.json during convert (template-url
# key).
template_repo = 'https://github.com/puppetlabs/pdk-templates'

describe 'pdk update', module_command: true do
  let(:no_output) { %r{\A\Z} }

  context 'with a fresh module' do
    include_context 'in a new module', 'clean_module', template: template_repo

    describe command('pdk update') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(no_output) }
      its(:stderr) { is_expected.to match(%r{already up to date}i) }
    end

    describe file('update_report.txt') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when run with --noop' do
    include_context 'in a new module', 'noop_out_of_date', template: template_repo

    before(:all) do
      FileUtils.rm_f '.travis.yml'
      metadata = JSON.parse(File.read('metadata.json'))
      metadata['template-ref'] = 'heads/master-0-g1234567'
      File.open('metadata.json', 'w') do |f|
        f.puts JSON.pretty_generate(metadata)
      end
    end

    describe command('pdk update --noop') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\n\.travis\.yml}mi) }
      its(:stdout) { is_expected.to match(%r{-+files to be modified-+\nmetadata\.json}mi) }
      its(:stderr) { is_expected.to match(%r{updating \w+?-noop_out_of_date using the default template}i) }
    end

    describe file('update_report.txt') do
      it { is_expected.to be_file }
    end

    describe file('.travis.yml') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when changes need to be made' do
    include_context 'in a new module', 'out_of_date', template: template_repo

    before(:all) do
      FileUtils.rm_f '.travis.yml'
      metadata = JSON.parse(File.read('metadata.json'))
      metadata['template-ref'] = 'heads/master-0-g1234567'
      File.open('metadata.json', 'w') do |f|
        f.puts JSON.pretty_generate(metadata)
      end
    end

    describe command('pdk update --force') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\n\.travis\.yml}mi) }
      its(:stdout) { is_expected.to match(%r{-+files to be modified-+\nmetadata\.json}mi) }
      its(:stderr) { is_expected.to match(%r{updating \w+?-out_of_date using the default template}i) }
    end

    describe file('update_report.txt') do
      it { is_expected.to be_file }
    end

    describe file('.travis.yml') do
      it { is_expected.to be_file }
    end
  end
end

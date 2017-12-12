require 'spec_helper_acceptance'

# Force the modules generated in these specs to use the public template repo to
# avoid unnecessary changes in the metadata.json during convert (template-url
# key).
template_repo = 'https://github.com/puppetlabs/pdk-templates'

describe 'pdk convert', module_command: true do
  let(:no_output) { %r{\A\Z} }

  context 'with a fresh module' do
    include_context 'in a new module', 'clean_module', template: template_repo

    describe command('pdk convert --force') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(no_output) }
      its(:stdout) { is_expected.to match(%r{no changes required}i) }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when run with --noop' do
    include_context 'in a new module', 'noop_with_changes', template: template_repo

    before(:all) do
      FileUtils.rm_f 'metadata.json'
    end

    describe command('pdk convert --noop --skip-interview') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(no_output) }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\nmetadata\.json}mi) }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end

    describe file('metadata.json') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when a file is missing' do
    include_context 'in a new module', 'missing_file', template: template_repo

    before(:all) do
      FileUtils.rm_f 'metadata.json'
    end

    describe command('pdk convert --force --skip-interview') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(no_output) }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\nmetadata\.json}mi) }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end

    describe file('metadata.json') do
      it { is_expected.to be_file }
      its(:content_as_json) { is_expected.to include('license' => anything) }
    end
  end
end

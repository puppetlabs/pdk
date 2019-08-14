require 'spec_helper_acceptance'

# Force the modules generated in these specs to use the public template repo to
# avoid unnecessary changes in the metadata.json during convert (template-url
# key).
template_repo = 'https://github.com/puppetlabs/pdk-templates'
pdk_convert_base = "pdk convert --template-url=#{template_repo}"

describe 'pdk convert', module_command: true do
  context 'with a fresh module' do
    include_context 'in a new module', 'clean_module', template: template_repo

    describe command("#{pdk_convert_base} --force") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
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
      File.open('.sync.yml', 'w') do |f|
        f.puts <<-EOS
---
.project:
  unmanaged: true
        EOS
      end
    end

    describe command("#{pdk_convert_base} --noop --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\nmetadata\.json}mi) }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end

    describe file('metadata.json') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when metadata.json file is missing' do
    include_context 'in a new module', 'missing_file', template: template_repo

    before(:all) do
      FileUtils.rm_f 'metadata.json'
      File.open('.sync.yml', 'w') do |f|
        f.puts <<-EOS
---
.project:
  unmanaged: true
        EOS
      end
    end

    describe command("#{pdk_convert_base} --force --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
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

  context 'when unmanaging a file' do
    include_context 'in a new module', 'unmanaged_file', template: template_repo

    before(:all) do
      File.open('.sync.yml', 'w') do |f|
        f.puts <<-EOS
---
.gitignore:
  unmanaged: true
        EOS
      end

      File.open('.gitignore', 'w') do |f|
        f.puts 'not supposed to be here'
      end
    end

    describe command("#{pdk_convert_base} --force --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
      its(:stdout) { is_expected.to match(%r{No changes required}i) }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when deleting a file' do
    include_context 'in a new module', 'deleted_file', template: template_repo

    before(:all) do
      File.open('.sync.yml', 'w') do |f|
        f.puts <<-EOS
---
.travis.yml:
  delete: true
        EOS
      end
    end

    describe command("#{pdk_convert_base} --force --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
      its(:stdout) { is_expected.to match(%r{-+files to be removed-+\n\.travis.yml}mi) }
    end

    describe file('.travis.yml') do
      it { is_expected.not_to be_file }
    end

    describe file('convert_report.txt') do
      it { is_expected.not_to be_file }
    end
  end

  context 'when an init-only templated file is missing' do
    include_context 'in a new module', 'init_missing', template: template_repo

    before(:all) do
      FileUtils.rm_f('README.md')
    end

    describe command("#{pdk_convert_base} --force --skip-interview") do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to have_no_output }
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\nREADME\.md}mi) }
      describe file('README.md') do
        it { is_expected.to be_file }
      end
    end
  end
end

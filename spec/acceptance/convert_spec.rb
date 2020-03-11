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
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\n.*/metadata\.json}mi) }
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
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\n.*/metadata\.json}mi) }
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
      its(:stdout) { is_expected.to match(%r{-+files to be removed-+\n.*/\.travis.yml}mi) }
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
      its(:stdout) { is_expected.to match(%r{-+files to be added-+\n.*/README\.md}mi) }
      describe file('README.md') do
        it { is_expected.to be_file }
      end
    end
  end

  context 'when converting to the default template' do
    include_context 'in a new module', 'non_default_template'

    around(:each) do |example|
      old_answer_file = ENV['PDK_ANSWER_FILE']
      ENV['PDK_ANSWER_FILE'] = File.expand_path(File.join('..', 'non_default_template_answers.json'))
      example.run
      ENV['PDK_ANSWER_FILE'] = old_answer_file
    end

    describe command('pdk convert --default-template --force') do
      its(:exit_status) { is_expected.to eq(0) }

      # Note - The following file(...) tests can not be run in isolation and require the above
      # `its(:exit_status)` to have run first.
      describe file('metadata.json') do
        its(:content_as_json) { is_expected.to include('template-url' => "#{template_repo}#master") }
      end

      describe file(File.join('..', 'non_default_template_answers.json')) do
        # Due to the serverspec file() resolving on the first pass, the file name will not be correct on the
        # second pass. To get around this we use the subject(...) to resolve the filename correctly.
        subject(:file_under_test) { file(File.join('..', 'non_default_template_answers.json')) }

        it 'has a nil template-url' do
          expect(file_under_test.content_as_json['template-url']).to be_nil
        end
      end
    end
  end

  context 'when adding missing tests' do
    # A real bare bones modules here. Testing to ensure that the functionality
    # works even when the module didn't have puppet-strings installed before
    # the convert.

    context 'to a module with no missing tests' do
      before(:all) do
        FileUtils.mkdir('module_with_all_tests')
        Dir.chdir('module_with_all_tests')

        FileUtils.mkdir_p('manifests')
        FileUtils.mkdir_p(File.join('spec', 'classes'))

        File.open(File.join('manifests', 'some_class.pp'), 'wb') do |f|
          f.puts 'class module_with_all_tests::some_class { }'
        end

        File.open(File.join('spec', 'classes', 'some_class_spec.rb'), 'wb') do |f|
          f.puts "require 'spec_helper'"
          f.puts "describe 'module_with_all_tests::some_class' do"
          f.puts 'end'
        end
      end

      after(:all) do
        Dir.chdir('..')
        FileUtils.rm_rf('module_with_all_tests')
      end

      describe command("#{pdk_convert_base} --force --skip-interview --add-tests") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.not_to match(%r{some_class_spec\.rb}m) }
      end
    end

    context 'to a module with missing tests' do
      before(:all) do
        FileUtils.mkdir('module_with_missing_tests')
        Dir.chdir('module_with_missing_tests')

        FileUtils.mkdir_p(File.join('manifests', 'namespaced'))

        File.open(File.join('manifests', 'some_class.pp'), 'wb') do |f|
          f.puts 'class module_with_missing_tests::some_class { }'
        end
        File.open(File.join('manifests', 'namespaced', 'some_define.pp'), 'wb') do |f|
          f.puts 'define module_with_missing_tests::namespaced::some_define() { }'
        end
      end

      after(:all) do
        Dir.chdir('..')
        FileUtils.rm_rf('module_with_missing_tests')
      end

      class_path = File.join('spec', 'classes', 'some_class_spec.rb')
      define_path = File.join('spec', 'defines', 'namespaced', 'some_define_spec.rb')

      describe command("#{pdk_convert_base} --force --skip-interview --add-tests") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{#{Regexp.escape(class_path)}}m) }
        its(:stdout) { is_expected.to match(%r{#{Regexp.escape(define_path)}}m) }

        describe file(class_path) do
          it { is_expected.to be_file }
          its(:content) { is_expected.to match(%r{describe 'module_with_missing_tests::some_class'}m) }
        end

        describe file(define_path) do
          it { is_expected.to be_file }
          its(:content) { is_expected.to match(%r{describe 'module_with_missing_tests::namespaced::some_define'}m) }
        end
      end
    end
  end
end

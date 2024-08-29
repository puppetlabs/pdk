require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk test unit', :module_command do
  include_context 'with a fake TTY'

  shared_context 'with spec file' do |filename, content|
    around do |example|
      path = File.join('spec', 'unit', filename)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'w') { |f| f.puts content }
      example.run
      FileUtils.rm_f(path)
    end
  end

  context 'when run inside of a module' do
    include_context 'in a new module', 'unit_test_module_new'

    describe command('pdk test unit --list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(/No unit test files with examples were found/) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
      its(:stdout) { is_expected.to match(/no examples found/i) }
      its(:stdout) { is_expected.to match(/0 examples, 0 failures/i) }
    end

    describe command('pdk test unit --parallel') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
      its(:stderr) { is_expected.to match(/No files for parallel_spec to run against/i) }
    end

    describe command('pdk test unit --parallel --format=text:test_output.txt') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
      its(:stderr) { is_expected.to match(/No examples found/i) }
    end

    context 'with passing tests' do
      # FIXME: facterversion pin and facterdb issues
      include_context 'with spec file', 'passing_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'passing test' do
          context 'On OS' do
            it 'should pass' do
              expect(true).to eq(true)
            end
          end
        end
      EOF

      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(/Test Files:.*passing_spec.rb/m) }
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
        its(:stdout) { is_expected.to match(/[1-9]\d* examples?.*0 failures/im) }
      end

      describe command('pdk test unit --parallel') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
        its(:stdout) { is_expected.to match(/[1-9]\d* examples?.*0 failures/im) }
      end
    end

    context 'with failing tests' do
      include_context 'with spec file', 'failing_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'failing test' do
          it 'should pass' do
            expect(false).to eq(true)
          end
        end
      EOF

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(/expected: true.*got: false/im) }
        its(:stdout) { is_expected.to match(/2 examples?.*1 failures?/im) }
      end
    end

    context 'with pending tests' do
      include_context 'with spec file', 'pending_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'pending test' do
          it 'should pass' do
            pending
            expect(false).to eq(true)
          end
        end
      EOF

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(/2 examples?.*0 failures.*1 pending/im) }
      end
    end

    context 'with syntax errors' do
      include_context 'with spec file', 'syntax_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'syntax error' do
          on_supported_os.each do |os, facts|
            context "On OS \#{os}" # THIS LINE IS BAD
              it 'should return a blank instance' do
                Hash.new.should == {}
              end
            end
          end
        end
      EOF

      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(/Unable to enumerate examples.*SyntaxError/m) }
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(/While loading .*syntax_spec.rb a `raise SyntaxError` occurred/) }
      end
    end

    context 'with multiple files with passing tests' do
      # FIXME: facterversion pin and facterdb issues
      include_context 'with spec file', 'passing_one_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'passing test' do
          on_supported_os(:facterversion => '2.4.6').each do |os, facts|
            context "On OS \#{os}" do
              it 'should pass' do
                expect(true).to eq(true)
              end
            end
          end
        end
      EOF
      include_context 'with spec file', 'passing_two_spec.rb', <<-EOF
        require 'spec_helper'

        RSpec.describe 'passing test' do
          on_supported_os(:facterversion => '2.4.6').each do |os, facts|
            context "On OS \#{os}" do
              it 'should pass' do
                expect(true).to eq(true)
              end
            end
          end
        end
      EOF

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(/[1-9]\d* examples?.*0 failures/im) }
      end

      describe command('pdk test unit --parallel') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(/[1-9]\d* processes for [1-9]\d* specs/m) }
        its(:stdout) { is_expected.to match(/[1-9]\d* examples?.*0 failures/im) }
      end
    end

    context 'with unbalanced json in the test descriptions' do
      include_context 'with spec file', 'unbalanced_json_spec.rb', <<-EOF
        RSpec.describe "broken-junit" do
          let(:large_nested_hash) do
            {
              single_one: 'single_one',
              single_two: 'single_two',
              single_three: 'single_three',
              single_four: 'single_four',
              single_five: 'single_five',
              nested: {
                nested_one: 'nested_one',
                nested_two: 'nested_two',
                nested_three: 'nested_three',
                nested_four: 'nested_four',
                nested_five: 'nested_five',
              },
            }
          end

          subject do
            large_nested_hash
          end

          it { is_expected.to be_a Hash }
          it { is_expected.to eq large_nested_hash }
        end
      EOF

      after(:all) do
        FileUtils.rm('report.xml')
        FileUtils.rm('report-parallel.xml')
      end

      describe command('pdk test unit --format junit:report.xml') do
        its(:exit_status) { is_expected.to eq(0) }

        describe file('report.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('rspec').with_attributes(
              'failures' => eq(0),
              'tests' => eq(2)
            )
          end
        end
      end

      describe command('pdk test unit --parallel --format junit:report-parallel.xml') do
        its(:exit_status) { is_expected.to eq(0) }

        describe file('report-parallel.xml') do
          its(:content) { is_expected.to contain_valid_junit_xml }

          its(:content) do
            is_expected.to have_junit_testsuite('rspec').with_attributes(
              'failures' => eq(0),
              'tests' => eq(2)
            )
          end
        end
      end
    end

    context 'when there is a problem setting up the fixtures' do
      before(:all) do
        File.open('.fixtures.yml', 'w') do |f|
          f.puts 'fixtures:'
          f.puts '  repositories:'
          f.puts '    "not_exist": "https://localhost/this/does/not/exist"'
        end
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(/preparing to run the unit tests/i) }
        its(:stderr) { is_expected.to match(%r{Failed to clone git repository https://localhost/this/does/not/exist}) }
        its(:stderr) { is_expected.not_to match(/Running unit tests\./) }
        its(:stderr) { is_expected.to match(/cleaning up after running unit tests/i) }
      end
    end
  end
end

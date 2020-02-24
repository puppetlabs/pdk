require 'spec_helper_acceptance'
require 'fileutils'

describe 'pdk test unit', module_command: true do
  include_context 'with a fake TTY'

  context 'when run inside of a module' do
    include_context 'in a new module', 'unit_test_module_new'

    describe command('pdk test unit --list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{No unit test files with examples were found}) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stdout) { is_expected.to match(%r{no examples found}i) }
      its(:stdout) { is_expected.to match(%r{0 examples, 0 failures}i) }
    end

    describe command('pdk test unit --parallel') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stderr) { is_expected.to match(%r{No files for parallel_spec to run against}i) }
    end

    context 'with passing tests' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        # FIXME: facterversion pin and facterdb issues
        File.open(File.join('spec', 'unit', 'passing_spec.rb'), 'w') do |f|
          f.puts <<-EOF
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
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.to eq 0 }
        its(:stdout) { is_expected.to match(%r{Test Files:.*passing_spec.rb}m) }
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
        its(:stdout) { is_expected.to match(%r{[1-9]\d* examples?.*0 failures}im) }
      end

      describe command('pdk test unit --parallel') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
        its(:stdout) { is_expected.to match(%r{[1-9]\d* examples?.*0 failures}im) }
      end
    end

    context 'with failing tests' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        File.open(File.join('spec', 'unit', 'failing_spec.rb'), 'w') do |f|
          f.puts <<-EOF
            require 'spec_helper'

            RSpec.describe 'failing test' do
              it 'should pass' do
                expect(false).to eq(true)
              end
            end
          EOF
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{expected: true.*got: false}im) }
        its(:stdout) { is_expected.to match(%r{1 examples?.*1 failures?}im) }
      end
    end

    context 'with pending tests' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        File.open(File.join('spec', 'unit', 'pending_spec.rb'), 'w') do |f|
          f.puts <<-EOF
            require 'spec_helper'

            RSpec.describe 'pending test' do
              it 'should pass' do
                pending
                expect(false).to eq(true)
              end
            end
          EOF
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{1 examples?.*0 failures.*1 pending}im) }
      end
    end

    context 'with syntax errors' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        spec_file = File.join(File.join('spec', 'unit', 'syntax_spec.rb'))
        File.open(spec_file, 'w') do |f|
          f.puts <<-EOF
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
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk test unit --list') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(%r{Unable to enumerate examples.*SyntaxError}m) }
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{An error occurred while loading.*syntax_spec.rb}) }
        its(:stdout) { is_expected.to match(%r{SyntaxError}) }
      end
    end

    context 'with multiple files with passing tests' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        # FIXME: facterversion pin and facterdb issues
        File.open(File.join('spec', 'unit', 'passing_one_spec.rb'), 'w') do |f|
          f.puts <<-EOF
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
        end
        File.open(File.join('spec', 'unit', 'passing_two_spec.rb'), 'w') do |f|
          f.puts <<-EOF
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
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk test unit') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{[1-9]\d* examples?.*0 failures}im) }
      end

      describe command('pdk test unit --parallel') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{[1-9]\d* processes for [1-9]\d* specs}m) }
        its(:stdout) { is_expected.to match(%r{[1-9]\d* examples?.*0 failures}im) }
      end
    end

    context 'with unbalanced json in the test descriptions' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        File.open(File.join('spec', 'unit', 'unbalanced_json_spec.rb'), 'w') do |f|
          f.puts <<-EOF
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
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
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
              'tests'    => eq(2),
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
              'tests'    => eq(2),
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
        its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
        its(:stderr) { is_expected.to match(%r{Failed to clone git repository https://localhost/this/does/not/exist}) }
        its(:stderr) { is_expected.not_to match(%r{Running unit tests\.}) }
        its(:stderr) { is_expected.to match(%r{cleaning up after running unit tests}i) }
      end
    end
  end
end

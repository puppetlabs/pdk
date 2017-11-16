require 'spec_helper_acceptance'
require 'fileutils'

describe 'Running unit tests' do
  include_context 'with a fake TTY'

  context 'with a fresh module' do
    include_context 'in a new module', 'unit_test_module_new'

    describe command('pdk test unit --list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{No unit test files with examples were found}) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stderr) { is_expected.to match(%r{running unit tests}i) }
      its(:stderr) { is_expected.to match(%r{no examples found}i) }
      its(:stderr) { is_expected.to match(%r{evaluated 0 tests}i) }
      its(:stderr) { is_expected.to match(%r{cleaning up after running unit tests}i) }
    end

    describe command('pdk test unit --parallel') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stderr) { is_expected.to match(%r{running unit tests in parallel}i) }
      its(:stderr) { is_expected.to match(%r{no examples found}i) }
      its(:stderr) { is_expected.to match(%r{evaluated 0 tests}i) }
      its(:stderr) { is_expected.to match(%r{cleaning up after running unit tests}i) }
    end
  end

  context 'with passing tests' do
    include_context 'in a new module', 'unit_test_module_pass'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      # FIXME: facterversion pin and facterdb issues
      File.open('spec/unit/passing_spec.rb', 'w') do |f|
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

    describe command('pdk test unit --list') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{Test Files:.*passing_spec.rb}m) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stderr) { is_expected.to match(%r{running unit tests.*5 tests.*0 failures}im) }
      its(:stderr) { is_expected.to match(%r{cleaning up after running unit tests}i) }
    end

    describe command('pdk test unit --parallel') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{preparing to run the unit tests}i) }
      its(:stderr) { is_expected.to match(%r{running unit tests in parallel.*5 tests.*0 failures}im) }
      its(:stderr) { is_expected.to match(%r{cleaning up after running unit tests}i) }
    end
  end

  context 'with failing tests' do
    include_context 'in a new module', 'unit_test_module_fail'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      File.open('spec/unit/failing_spec.rb', 'w') do |f|
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

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{failed.*expected: true.*got: false}im) }
      its(:stderr) { is_expected.to match(%r{running unit tests.*1 tests.*1 failures}im) }
    end
  end

  context 'with pending tests' do
    include_context 'in a new module', 'unit_test_module_pending'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      File.open('spec/unit/pending_spec.rb', 'w') do |f|
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

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{running unit tests.*1 tests.*0 failures.*1 pending}im) }
    end
  end

  context 'with syntax errors' do
    include_context 'in a new module', 'unit_test_module_pending'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      spec_file = File.join('spec/unit/syntax_spec.rb')
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

    describe command('pdk test unit --list') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{Unable to enumerate examples.*SyntaxError}m) }
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{An error occurred while loading.*syntax_spec.rb}) }
      its(:stderr) { is_expected.to match(%r{SyntaxError}) }
    end
  end

  context 'multiple files with passing tests' do
    include_context 'in a new module', 'unit_test_module_multiple_pass'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      # FIXME: facterversion pin and facterdb issues
      File.open('spec/unit/passing_one_spec.rb', 'w') do |f|
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
      File.open('spec/unit/passing_two_spec.rb', 'w') do |f|
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

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{running unit tests.*10 tests.*0 failures}im) }
    end

    describe command('pdk test unit --parallel') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{running unit tests in parallel.*10 tests.*0 failures}im) }
    end
  end

  context 'when there is a problem setting up the fixtures' do
    include_context 'in a new module', 'bad_fixtures'

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

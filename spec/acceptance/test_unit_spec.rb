require 'spec_helper_acceptance'
require 'fileutils'

describe 'Running unit tests' do
  context 'with a fresh module' do
    include_context 'in a new module', 'unit_test_module_new'

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{running unit tests}i) }
      its(:stderr) { is_expected.to match(%r{no examples found}i) }
      its(:stderr) { is_expected.to match(%r{evaluated 0 tests}i) }
    end
  end

  context 'with passing tests' do
    include_context 'in a new module', 'unit_test_module_pass'

    before(:all) do
      FileUtils.mkdir_p('spec/unit')
      File.open('spec/unit/passing_spec.rb', 'w') do |f|
        f.puts <<-EOF
          require 'spec_helper'

          RSpec.describe 'test' do
            it 'should pass' do
              expect(true).to eq(true)
            end
          end
        EOF
      end
    end

    describe command('pdk test unit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{running unit tests.*1 tests.*0 failures}im) }
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
end

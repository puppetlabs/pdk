require 'spec_helper_acceptance'

describe 'pdk validate ruby', module_command: true do
  include_context 'with a fake TTY'

  context 'when run inside of a module' do
    include_context 'in a new module', 'validate_ruby'

    context 'with a style violation' do
      spec_violation_rb = File.join('spec', 'violation.rb')

      before(:all) do
        File.open(spec_violation_rb, 'w') do |f|
          f.puts "# frozen_string_literal: true\n\n"
          f.puts 'f = %(x y z)'
        end
      end

      after(:all) do
        FileUtils.rm(spec_violation_rb)
      end

      describe command('pdk validate ruby') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{useless assignment.*\(#{Regexp.escape(spec_violation_rb)}.*\)}i) }
        its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
      end

      # Make use of the offending file above to test that target selection works
      # as expected.
      context 'when validating specific files' do
        describe command("pdk validate ruby #{File.join('spec', 'spec_helper.rb')}") do
          its(:exit_status) { is_expected.to eq(0) }
          its(:stdout) { is_expected.to have_no_output }
          its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
        end
      end

      context 'when validating specific directories' do
        another_violation_rb = File.join('spec', 'fixtures', 'test', 'another_violation.rb')

        before(:all) do
          FileUtils.mkdir_p(File.dirname(another_violation_rb))
          File.open(another_violation_rb, 'w') do |f|
            f.puts "# frozen_string_literal: true\n\n"
            f.puts "puts {:foo => 'bar'}.inspect"
          end
        end

        after(:all) do
          FileUtils.rm_rf(File.dirname(another_violation_rb))
        end

        describe command("pdk validate ruby #{File.join('spec', 'fixtures')}") do
          its(:exit_status) { is_expected.not_to eq(0) }
          its(:stdout) { is_expected.to match(%r{#{Regexp.escape(another_violation_rb)}}) }
          its(:stdout) { is_expected.not_to match(%r{#{Regexp.escape(spec_violation_rb)}}) }
          its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
        end

        describe command('pdk validate ruby --format junit') do
          its(:exit_status) { is_expected.not_to eq(0) }
          its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
          its(:stdout) { is_expected.to contain_valid_junit_xml }

          its(:stdout) do
            is_expected.to have_junit_testsuite('rubocop').with_attributes(
              'failures' => a_value >= 1,
              'tests'    => a_value >= 2,
            )
          end

          its(:stdout) do
            is_expected.to have_junit_testcase.in_testsuite('rubocop').with_attributes(
              'classname' => 'rubocop',
              'name'      => File.join('spec', 'spec_helper.rb'),
            ).that_passed
          end

          its(:stdout) do
            is_expected.not_to have_junit_testcase.in_testsuite('rubocop').with_attributes(
              'name' => a_string_starting_with(File.join('spec', 'fixtures')),
            )
          end
        end
      end
    end

    context 'when auto-correcting violations' do
      before(:all) do
        File.open('test.rb', 'w') do |f|
          f.puts "# frozen_string_literal: true\n\n"
          f.puts "puts({'a' => 'b'}.inspect)"
        end
      end

      after(:all) do
        FileUtils.rm('test.rb')
      end

      describe command('pdk validate ruby --auto-correct') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\(corrected\):.*space inside (\{|\}) missing.*\(test\.rb.*\)}i) }
      end

      describe command('pdk validate ruby') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
      end
    end

    context 'with lots of files' do
      before(:all) do
        FileUtils.mkdir_p(File.join('spec', 'unit'))
        (1..5000).each do |num|
          File.open(File.join('spec', 'unit', "test#{num}.rb"), 'w') do |f|
            f.puts "# frozen_string_literal: true\n\n"
            f.puts "puts({ 'a' => 'b' }.inspect)"
          end
        end
      end

      after(:all) do
        FileUtils.rm_rf(File.join('spec', 'unit'))
      end

      describe command('pdk validate ruby') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to have_no_output }
      end
    end
  end
end

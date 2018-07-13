require 'spec_helper_acceptance'

describe 'pdk validate ruby', module_command: true do
  let(:empty_string) { %r{\A\Z} }
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  include_context 'with a fake TTY'

  context 'with a style violation' do
    include_context 'in a new module', 'foo'

    spec_violation_rb = File.join('spec', 'violation.rb')

    before(:all) do
      File.open(spec_violation_rb, 'w') do |f|
        f.puts 'f = %(x y z)'
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{#{Regexp.escape(spec_violation_rb)}.*useless assignment}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    # Make use of the offending file above to test that target selection works
    # as expected.
    context 'when validating specific files' do
      describe command("pdk validate ruby #{File.join('spec', 'spec_helper.rb')}") do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stdout) { is_expected.to match(%r{\A\Z}) }
        its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      end
    end

    context 'when validating specific directories' do
      another_violation_rb = File.join('lib', 'puppet', 'another_violation.rb')

      before(:all) do
        FileUtils.mkdir_p(File.dirname(another_violation_rb))
        File.open(another_violation_rb, 'w') do |f|
          f.puts "puts {:foo => 'bar'}.inspect"
        end
      end

      describe command('pdk validate ruby lib') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stdout) { is_expected.to match(%r{#{Regexp.escape(another_violation_rb)}}) }
        its(:stdout) { is_expected.not_to match(%r{#{Regexp.escape(spec_violation_rb)}}) }
        its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      end
    end

    describe command('pdk validate ruby --format junit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      it_behaves_like :it_generates_valid_junit_xml

      its(:stdout) do
        is_expected.to have_junit_testsuite('rubocop').with_attributes(
          'failures' => a_value > 1,
          'tests'    => a_value >= 3,
        )
      end

      its(:stdout) do
        is_expected.to have_junit_testcase.in_testsuite('rubocop').with_attributes(
          'classname' => 'rubocop',
          'name'      => File.join('spec', 'spec_helper.rb'),
        ).that_passed
      end

      its(:stdout) do
        is_expected.to have_junit_testcase.in_testsuite('rubocop').with_attributes(
          'classname' => a_string_matching(%r{UselessAssignment}),
          'name'      => a_string_starting_with(File.join('spec', 'violation.rb')),
        ).that_failed
      end
    end
  end

  context 'when auto-correcting violations' do
    include_context 'in a new module', 'foo'

    before(:all) do
      File.open('test.rb', 'w') do |f|
        f.puts "puts({'a' => 'b'}.inspect)"
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stdout) { is_expected.to match(%r{test\.rb.*space inside (\{|\}) missing}i) }
    end

    describe command('pdk validate ruby --auto-correct') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{^corrected:.*test\.rb.*space inside (\{|\}) missing}i) }
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
    end
  end

  context 'with lots of files' do
    include_context 'in a new module', 'file_dump'

    before(:all) do
      FileUtils.mkdir_p(File.join('spec', 'unit'))
      (1..5000).each do |num|
        File.open(File.join('spec', 'unit', "test#{num}.rb"), 'w') do |f|
          f.puts "puts({ 'a' => 'b' }.inspect)"
        end
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(empty_string) }
    end
  end
end

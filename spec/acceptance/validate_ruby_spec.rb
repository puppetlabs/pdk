require 'spec_helper_acceptance'

describe 'pdk validate ruby', module_command: true do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  context 'with a fresh module' do
    include_context 'in a new module', 'foo'

    example_rb = File.join('spec', 'example.rb')

    before(:all) do
      File.open(example_rb, 'w') do |f|
        f.puts "require 'filepath'"
      end
    end

    describe command('pdk validate ruby') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stdout) { is_expected.to match(%r{\A\Z}) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    describe command('pdk validate ruby --format junit') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{checking ruby code style}i) }
      it_behaves_like :it_generates_valid_junit_xml

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]').with_attributes(
          'failures' => '0',
          'tests'    => satisfy { |v| v.to_i > 0 },
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]/testcase').with_attributes(
          'classname' => 'rubocop',
          'name'      => example_rb,
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]/testcase').with_attributes(
          'classname' => 'rubocop',
          'name'      => File.join('spec', 'spec_helper.rb'),
        )
      end
    end
  end

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
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]').with_attributes(
          'failures' => satisfy { |v| v.to_i > 0 },
          'tests'    => satisfy { |v| v.to_i >= 3 },
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]/testcase').with_attributes(
          'classname' => 'rubocop',
          'name'      => File.join('spec', 'spec_helper.rb'),
        )
      end

      its(:stdout) do
        is_expected.to have_xpath('/testsuites/testsuite[@name="rubocop"]/testcase').with_attributes(
          'classname' => a_string_matching(%r{UselessAssignment}),
          'name'      => a_string_starting_with(File.join('spec', 'violation.rb')),
        )
      end
    end
  end
end

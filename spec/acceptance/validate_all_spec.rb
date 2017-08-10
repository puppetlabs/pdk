require 'spec_helper_acceptance'

describe 'Running all validations' do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  context 'with a fresh module' do
    include_context 'in a new module', 'validate_all'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# validate_all
class validate_all { }
        EOS
      end
    end

    describe command('pdk validate') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata syntax \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata style \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end
  end

  context 'with a puppet syntax failure should still run all validators' do
    include_context 'in a new module', 'validate_all'

    init_pp = File.join('manifests', 'init.pp')

    before(:all) do
      File.open(init_pp, 'w') do |f|
        f.puts <<-EOS
# foo
class validate_all {
  Fails here because of gibberish
}
        EOS
      end
    end

    describe command('pdk validate') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata syntax \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata style \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    describe command('pdk validate --parallel') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Validating module using \d+ threads}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata syntax \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata style \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stdout) { is_expected.to match(%r{Error: This Name has no effect}i) }
      its(:stdout) { is_expected.to match(%r{Error: This Type-Name has no effect}i) }
      its(:stdout) { is_expected.to match(%r{Error: Language validation logged 2 errors. Giving up}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    describe command('pdk validate --format junit') do
      its(:exit_status) { is_expected.not_to eq(0) }
      its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata syntax \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata style \(metadata\.json\)}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stderr) { is_expected.not_to match(%r{Checking Puppet manifest style}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
      its(:stdout) { is_expected.to pass_validation(junit_xsd) }

      its(:stdout) do
        is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
          'failures' => eq(3),
          'tests'    => eq(3),
        )
      end

      its(:stdout) do
        is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
          'classname' => 'puppet-syntax',
          'name'      => a_string_starting_with(init_pp),
        ).that_failed(
          'type'    => 'Error',
          'message' => a_string_matching(%r{This Name has no effect}i),
        )
      end

      its(:stdout) do
        is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
          'classname' => 'puppet-syntax',
          'name'      => a_string_starting_with(init_pp),
        ).that_failed(
          'type'    => 'Error',
          'message' => a_string_matching(%r{This Type-Name has no effect}i),
        )
      end
    end
  end
end

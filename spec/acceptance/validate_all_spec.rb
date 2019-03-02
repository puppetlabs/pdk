require 'spec_helper_acceptance'

describe 'pdk validate', module_command: true do
  let(:junit_xsd) { File.join(RSpec.configuration.fixtures_path, 'JUnit.xsd') }

  include_context 'with a fake TTY'

  context 'when run inside of a module' do
    include_context 'in a new module', 'validate_all'

    before(:all) do
      File.open(File.join('manifests', 'init.pp'), 'w') do |f|
        f.puts <<-EOS
# validate_all
class validate_all { }
        EOS
      end
    end

    describe command('pdk validate') do
      its(:exit_status) { is_expected.to eq(0) }
      its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
      its(:stderr) { is_expected.to match(%r{Checking metadata syntax}i) }
      its(:stderr) { is_expected.to match(%r{Checking module metadata style}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
      its(:stderr) { is_expected.to match(%r{Checking Puppet manifest style}i) }
      its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
    end

    context 'with a puppet syntax failure should still run all validators' do
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

      describe command('pdk validate --format text:stdout --format junit:report.xml') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
        its(:stderr) { is_expected.to match(%r{Checking metadata syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking module metadata style}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }

        describe file('report.xml') do
          its(:content) { is_expected.to pass_validation(junit_xsd) }

          its(:content) do
            is_expected.to have_junit_testsuite('puppet-syntax').with_attributes(
              'failures' => eq(3),
              'tests'    => eq(3),
            )
          end

          its(:content) do
            is_expected.to have_junit_testcase.in_testsuite('puppet-syntax').with_attributes(
              'classname' => 'puppet-syntax',
              'name'      => a_string_starting_with(init_pp),
            ).that_failed(
              'type'    => 'Error',
              'message' => a_string_matching(%r{This Name has no effect}i),
            )
          end

          its(:content) do
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

      describe command('pdk validate --parallel') do
        its(:exit_status) { is_expected.not_to eq(0) }
        its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
        its(:stderr) { is_expected.to match(%r{Validating module using \d+ threads}i) }
        its(:stderr) { is_expected.to match(%r{Checking metadata syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking module metadata style}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stdout) { is_expected.to match(%r{Error:.*This Name has no effect}i) }
        its(:stdout) { is_expected.to match(%r{Error:.*This Type-Name has no effect}i) }
        its(:stdout) { is_expected.to match(%r{Error:.*Language validation logged 2 errors. Giving up}i) }
        its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
      end
    end

    context "when 'pdk' is included in the Gemfile" do
      before(:all) do
        File.open('Gemfile', 'a') do |f|
          f.puts "gem 'pdk', path: '#{File.expand_path(File.join(__FILE__, '..', '..', '..'))}'"
        end

        File.open(File.join('manifests', 'init.pp'), 'w') do |f|
          f.puts <<-EOS.gsub(%r{^ {10}}, '')
            # pdk_in_gemfile
            class pdk_in_gemfile { }
          EOS
        end
      end

      describe command('pdk validate') do
        its(:exit_status) { is_expected.to eq(0) }
        its(:stderr) { is_expected.to match(%r{Running all available validators}i) }
        its(:stderr) { is_expected.to match(%r{Checking metadata syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking module metadata style}i) }
        its(:stderr) { is_expected.to match(%r{Checking Puppet manifest syntax}i) }
        its(:stderr) { is_expected.to match(%r{Checking Ruby code style}i) }
      end
    end
  end
end
